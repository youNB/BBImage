//
//  NSObject+BBImage.m
//  BBImage
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "NSObject+BBImage.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (BBImage)

- (void)setMd5:(NSString *)md5{
    objc_setAssociatedObject(self, "md5", md5, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)md5{
    NSString *md5 = objc_getAssociatedObject(self, "md5");
    if(!md5){
        md5 = [self toMD5];
        [self setMd5:md5];
    }
    
    return md5;
}

- (NSString *)toMD5{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    NSMutableString *md5 = [NSMutableString string];
    for(NSInteger index = 0; index < 16; index++){
        [md5 appendFormat:@"%02x",result[index]];
    }
    
    return md5;
}

@end

@implementation NSURLSession (BBImage)

- (void)setTasks:(NSInteger)tasks{
    objc_setAssociatedObject(self, "tasks", @(MAX(0, tasks)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)tasks{
    NSNumber *number = objc_getAssociatedObject(self, "tasks");
    return [number integerValue];
}

@end

@implementation NSURL (BBImage)

+ (void)load{
    static dispatch_once_t once_t = 0;
    dispatch_once(&once_t, ^{
        Method pre = class_getClassMethod([self class], @selector(URLWithString:));
        Method now = class_getClassMethod([self class], @selector(nowURLWithString:));
        method_exchangeImplementations(pre, now);
    });
}

+ (instancetype)nowURLWithString:(NSString *)URLString{
    if(!URLString){return nil;}
    
    NSURL *URL = [self nowURLWithString:URLString];
    if(URL){return URL;}
    
    NSCharacterSet *set = [NSCharacterSet URLQueryAllowedCharacterSet];
    URLString = [URLString stringByAddingPercentEncodingWithAllowedCharacters:set];
    return [self nowURLWithString:URLString];
}

@end

