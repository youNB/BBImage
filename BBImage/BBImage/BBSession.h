//
//  BBSession.h
//  BBImage
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BBSession : NSObject

/*
    session即会话，我们希望session可以进行复用，防止每次都要重新链接
*/
+ (BBSession *)sharedManager;

//获取session
- (NSURLSession *)session;

@end

