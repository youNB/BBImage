//
//  BBThread.h
//  BBThread
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBThread : NSObject

/*
    单例，该工具类中凡是参数叫thread的，里面的操作都是在子线程中进行，凡是叫main的都是主线程的操作，凡是叫handle的，有可能在子线程中，也有可能在主线程中。NSThread和NSOperation的手动启动未考虑在内，建议不使用手动启动
*/
+ (BBThread *)sharedManager;

/*
    开辟子线程
*/
- (void)thread:(void (^)(void))thread;

- (void)priority:(long)priority
          thread:(void (^)(void))thread;

/*
    同步，相当于@synchronized/NSLock，但是比之高效一个量级
    尽量不要在handle里面做耗时操作
*/
- (void)sync:(void (^)(void))handle;

/*
    延迟delay时间后执行
*/
- (void)delay:(double)delay
       main:(void (^)(void))main;

- (void)delay:(double)delay
       thread:(void (^)(void))thread;

/*
    operationQueue,本质是对dispatch的封装，其他同上
    config,可对operation进行进一步设置
*/
- (void)operation:(void (^)(void))thread;

- (void)operation:(void (^)(NSBlockOperation *operation))config
           handle:(void (^)(void))thread;

//获取到线程队列
- (NSOperationQueue *)currentQueue;

//获取到子线程
- (NSThread *)currentThread;

@end

