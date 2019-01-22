//
//  BBSession.m
//  BBImage
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "BBSession.h"
#import "NSObject+BBImage.h"

@interface BBSession()
@property(nonatomic, strong) NSArray *sessions;
@end

@implementation BBSession

+ (BBSession *)sharedManager{
    static BBSession *manager     = nil;
    static dispatch_once_t once_t = 0;
    dispatch_once(&once_t, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (instancetype)init{
    if([super init]){
        NSURLSessionConfiguration *configure = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configure.URLCache = nil;     //不自动缓存，手动缓存
        configure.discretionary = YES;//自动选择最佳网络
        configure.allowsCellularAccess = YES;//允许蜂窝
        configure.HTTPShouldUsePipelining = YES;//极大的加快响应速度，不过浏览器一般不支持，写着吧，万一有支持的呢
        
        NSMutableArray *array = [NSMutableArray array];
        char max = MAX(1, configure.HTTPMaximumConnectionsPerHost);
        for(char idx = 0; idx < max; idx ++){
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configure];
            [array addObject:session];
        }
        _sessions = array;
    }
    return self;
}


//获取session
- (NSURLSession *)session{
    NSURLSession *s = self.sessions.firstObject;
    if(!s.tasks){return s;}
    for(char i = 1; i < self.sessions.count; i ++){
        NSURLSession *ss = self.sessions[i];
        if(!ss.tasks){return ss;}
        if(ss.tasks < s.tasks){s = ss;}
    }
    return s;
}

@end
