//
//  BBImageManager.m
//  BBImage
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "BBImageManager.h"
#import "BBThread.h"
#import "BBSession.h"
#import "NSObject+BBImage.h"

#define BBRequestTimeout  20      //超时时间
#define BBCacheCountLimit 50      //持有住50张image,如果app内以image为主，或者会涉及到很多image，可以增大这个值
#define BBCacheCostLimit  5242880 //5 * 1024 * 1024，即5M，指内存缓存image的容量不超过5M，其他同上，上下两个设置是交集关系

@interface BBImageManager()
@property(nonatomic, strong) NSString *stored_dir;//图片存储的文件夹
@property(nonatomic, strong) NSCache  *mem_cache; //内存缓存
@property(nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<void (^)(UIImage *BBImage, NSString *md5, NSError *error)> *> *key_values;
@property(nonatomic, assign) UIBackgroundTaskIdentifier task_identifier;
@end

@implementation BBImageManager

//单例
+ (BBImageManager *)sharedManager{
    static BBImageManager *manager = nil;
    static dispatch_once_t once_t  = 0;
    dispatch_once(&once_t, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (instancetype)init{
    if([super init]){
        SEL back_sel = @selector(appDidEnterBackground:);
        SEL fore_sel = @selector(appDidEnterForeground:);
        const NSNotificationName back = UIApplicationDidEnterBackgroundNotification;
        const NSNotificationName fore = UIApplicationWillEnterForegroundNotification;
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:back_sel
                                                   name:back
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:fore_sel
                                                   name:fore
                                                 object:nil];
        
    }
    return self;
}

//程序进入后台，申请额外执行时间，防止当前正在下载图片被中断
- (void)appDidEnterBackground:(UIApplication *)app{
    _task_identifier = [app beginBackgroundTaskWithName:@"my_task"
                                      expirationHandler:^{
        [app endBackgroundTask:self.task_identifier];
        self.task_identifier = UIBackgroundTaskInvalid;
    }];
}

- (void)appDidEnterForeground:(UIApplication *)app{
    if(self.task_identifier == UIBackgroundTaskInvalid){return;}
    [app endBackgroundTask:self.task_identifier];
    self.task_identifier = UIBackgroundTaskInvalid;
}

- (BOOL)imageCached:(NSString *)link{
    NSFileManager *file_manager = NSFileManager.defaultManager;
    NSString *path = [NSString stringWithFormat:@"%@/%@", self.stored_dir, link.md5];
    return [file_manager fileExistsAtPath:path];
}

- (UIImage *)imageFromMemory:(NSString *)link{
    if(!link.md5){return nil;}
    return [self.mem_cache objectForKey:link.md5];
}

- (void)cacheImageToMemory:(UIImage *)image
                       key:(NSString *)link{
    if(!link.md5){return;}
    [self.mem_cache setObject:image forKey:link.md5];
}

- (void)imageFromDisk:(NSString *)link
             callback:(void (^)(UIImage *BBImage, NSString *md5))callback{
    NSAssert(callback, @"请实现回调");
    NSString *path = [NSString stringWithFormat:@"%@/%@",self.stored_dir, link.md5];
    [BBThread.sharedManager priority:DISPATCH_QUEUE_PRIORITY_BACKGROUND
                              thread:^{
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        [self cacheImageToMemory:image key:link];
        callback(image, link.md5);
    }];
}

- (void)cacheImageToDisk:(NSString *)link fromData:(NSData *)data{
    NSString *path = [NSString stringWithFormat:@"%@/%@",self.stored_dir, link.md5];
    [BBThread.sharedManager priority:DISPATCH_QUEUE_PRIORITY_BACKGROUND
                              thread:^{[data writeToFile:path atomically:YES];}];
}

- (void)cacheImageToDisk:(NSString *)link fromFile:(NSString *)file{
    NSString *path = [NSString stringWithFormat:@"%@/%@",self.stored_dir, link.md5];
    NSFileManager *file_manager = NSFileManager.defaultManager;
    [BBThread.sharedManager priority:DISPATCH_QUEUE_PRIORITY_BACKGROUND thread:^{
        [file_manager moveItemAtPath:file toPath:path error:nil];
    }];
}

- (void)cacheImageToDisk:(NSString *)link fromURL:(NSURL *)URL{
    NSString *path = [NSString stringWithFormat:@"%@/%@",self.stored_dir, link.md5];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSFileManager *file_manager = NSFileManager.defaultManager;
    [file_manager moveItemAtURL:URL toURL:url error:nil];
}

- (void)imageFromUrl:(NSString *)link
            callback:(void (^)(UIImage *BBImage, NSString *md5, NSError *error))callback{
    NSAssert(callback, @"请实现回调");
    NSURL *URL = [NSURL URLWithString:link];
    if(!URL){
        NSError *error = [NSError errorWithDomain:@"图片链接有误" code:BBRequestError userInfo:@{}];
        callback(nil, link.md5, error);
        return;
    }
    
    NSMutableArray *values = self.key_values[link.md5];
    if(!values){
        values = [NSMutableArray array];
        self.key_values[URL.absoluteString.md5] = values;
    }
    [values addObject:callback];
    
    //发请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.timeoutInterval = BBRequestTimeout;
    NSURLSession *session = BBSession.sharedManager.session;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *Error = nil;
        UIImage *image = nil;
        if(error){Error = error;}
        else if(!data.length){Error = [NSError errorWithDomain:@"暂无数据" code:BBRequestError userInfo:@{}];}
        else{
            image = [UIImage imageWithData:data];
            if(!image){Error = [NSError errorWithDomain:@"图片资源有误" code:BBRequestError userInfo:@{}];}
        }
        
        if(!Error){
            [self cacheImageToDisk:link fromData:data];//存磁盘
            [self cacheImageToMemory:image key:link];  //存内存
        }
        
        //数据回调
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *values = self.key_values[link.md5];
            for(void (^callback)(UIImage *BBImage, NSString *md5, NSError *ERROR) in values){
                callback(image, link.md5, Error);
            }
            self.key_values[link.md5] = nil;
        });
    }];
    [task resume];
}

//lazy load
- (NSString *)stored_dir{
    if(!_stored_dir){//注意，这里最好用cachesDirectory
        NSString *path = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).lastObject;
        _stored_dir = [NSString stringWithFormat:@"%@/BBImageDirectory",path];
        NSFileManager *file_manager = NSFileManager.defaultManager;
        if(![file_manager fileExistsAtPath:_stored_dir]){
            [file_manager createDirectoryAtPath:_stored_dir
                    withIntermediateDirectories:YES
                                     attributes:nil
                                          error:nil];
        }
    }
    return _stored_dir;
}

- (NSCache *)mem_cache{
    if(!_mem_cache){
        _mem_cache = [[NSCache alloc]init];
        _mem_cache.countLimit = BBCacheCountLimit;
        _mem_cache.totalCostLimit = BBCacheCostLimit;
    }
    return _mem_cache;
}

- (NSMutableDictionary<NSString *,NSMutableArray<void (^)(UIImage *, NSString *, NSError *)> *> *)key_values{
    if(!_key_values){
        _key_values = [NSMutableDictionary dictionary];
    }
    return _key_values;
}

@end
