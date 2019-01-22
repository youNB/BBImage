//
//  NSObject+BBImage.h
//  BBImage
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BBImage)
@property(nonatomic, strong) NSString *md5;
- (NSString *)toMD5;
@end

@interface NSURLSession (BBImage)
@property(nonatomic, assign) NSInteger tasks;//session上挂接的任务数
@end

@interface NSURL (BBImage)
@end
