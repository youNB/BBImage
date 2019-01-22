//
//  BBImageManager.h
//  BBImage
//
//  Created by 程肖斌 on 2019/1/22.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BBRequest) {
    BBRequestSuccess,
    BBRequestNoNet,
    BBRequestError
};

@interface BBImageManager : NSObject

//单例
+ (BBImageManager *)sharedManager;

/*
    判断图片是否在本地缓存
    link:图片链接地址
*/
- (BOOL)imageCached:(NSString *)link;

/*
    从内存获取image
    link:图片链接
*/
- (UIImage *)imageFromMemory:(NSString *)link;

/*
    将图片缓存进内存
    image：要缓存的图片
    link：图片的链接
*/
- (void)cacheImageToMemory:(UIImage *)image
                       key:(NSString *)link;

/*
    从磁盘中获取图片
    link:图片的链接
    这个方法会自动缓存到内存
*/
- (void)imageFromDisk:(NSString *)link
             callback:(void (^)(UIImage *BBImage, NSString *md5))callback;

/*
    将图片缓存进磁盘
    link:图片链接
    data:图片数据
    file：需要挪动的图片的位置
    URL:从URL拷贝到URL
*/
- (void)cacheImageToDisk:(NSString *)link fromData:(NSData *)data;

- (void)cacheImageToDisk:(NSString *)link fromFile:(NSString *)file;

- (void)cacheImageToDisk:(NSString *)link fromURL:(NSURL *)URL;

/*
    从网络获取;
    获取到数据后会自动进行内存/磁盘的缓存
*/
- (void)imageFromUrl:(NSString *)link
            callback:(void (^)(UIImage *BBImage, NSString *md5, NSError *error))callback;

@end

