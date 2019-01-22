//
//  BBThread.m
//  BBThread
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "BBThread.h"

#define max_signals 6   //最大信号量6

@interface BBThread()
@property(nonatomic, strong) dispatch_semaphore_t semaphore_t;
@property(nonatomic, strong) dispatch_semaphore_t one_sema_t;
@property(nonatomic, strong) NSOperationQueue     *operation_queue;
@property(nonatomic, strong) NSThread             *thread_t;
@end

@implementation BBThread

+ (BBThread *)sharedManager{
    static BBThread *manager      = nil;
    static dispatch_once_t once_t = 0;
    dispatch_once(&once_t, ^{
        manager = [[self alloc]init];
    });
    return manager;
}

- (instancetype)init{
    if([super init]){
        _semaphore_t = dispatch_semaphore_create(max_signals);
        _one_sema_t  = dispatch_semaphore_create(1);
        _operation_queue = [[NSOperationQueue alloc]init];
        _operation_queue.maxConcurrentOperationCount = max_signals;
        SEL sel      = @selector(createSingleThread);
        _thread_t    = [[NSThread alloc]initWithTarget:self
                                              selector:sel
                                                object:nil];
        [_thread_t start];
    }
    return self;
}

- (void)createSingleThread{//信号量的等待放在子线程里等
    [[NSThread currentThread] setName:@"single.thread.deal"];
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [loop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
    [loop run];
}

- (void)semaphore:(NSDictionary *)param{
    dispatch_semaphore_wait(self.semaphore_t, DISPATCH_TIME_FOREVER);
    long priority = [param[@"priority"] longValue];
    void (^handle)(void) = param[@"handle"];
    dispatch_queue_t queue_t = dispatch_get_global_queue(priority, 0);
    dispatch_async(queue_t, ^{handle(); dispatch_semaphore_signal(self.semaphore_t);});
}

- (void)thread:(void (^)(void))thread{
    NSAssert(thread, @"请实现回调");
    NSDictionary *param = @{@"priority" : @(DISPATCH_QUEUE_PRIORITY_DEFAULT),
                            @"handle"   : thread};
    [self performSelector:@selector(semaphore:)
                 onThread:self.thread_t
               withObject:param
            waitUntilDone:NO];
}

- (void)priority:(long)priority
          thread:(void (^)(void))thread{
    NSAssert(thread, @"请实现回调");
    NSDictionary *param = @{@"priority" : @(priority),
                            @"handle"   : thread};
    [self performSelector:@selector(semaphore:)
                 onThread:self.thread_t
               withObject:param
            waitUntilDone:NO];
}

- (void)sync:(void (^)(void))handle{
    NSAssert(handle, @"请实现回调");
    dispatch_semaphore_wait(self.one_sema_t, DISPATCH_TIME_FOREVER);
    handle();
    dispatch_semaphore_signal(self.one_sema_t);
}

- (void)delay:(double)delay
     isOnMain:(BOOL)isOnMain
       handle:(void (^)(void))handle{
    NSAssert(handle, @"请实现回调");
    dispatch_time_t time_t = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_queue_t queue_t = 0;
    if(isOnMain){queue_t = dispatch_get_main_queue();}
    else{
        long priority = DISPATCH_QUEUE_PRIORITY_DEFAULT;
        queue_t = dispatch_get_global_queue(priority, 0);
    }
    dispatch_after(time_t, queue_t, handle);
}
- (void)delay:(double)delay
         main:(void (^)(void))main{
    [self delay:delay isOnMain:YES handle:main];
}

- (void)delay:(double)delay
       thread:(void (^)(void))thread{
    [self delay:delay isOnMain:NO handle:thread];
}

- (void)operation:(void (^)(void))thread{
    NSAssert(thread, @"请实现回调");
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:thread];
    [self.operation_queue addOperation:operation];
}

- (void)operation:(void (^)(NSBlockOperation *operation))config
           handle:(void (^)(void))thread{
    NSAssert(thread, @"请实现回调");
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:thread];
    !config ?: config(operation);
    [self.operation_queue addOperation:operation];
}

//获取到线程队列
- (NSOperationQueue *)currentQueue{
    return self.operation_queue;
}

//获取到子线程
- (NSThread *)currentThread{
    return self.thread_t;
}

@end
