//
//  ViewController.m
//  BBImage
//
//  Created by 程肖斌 on 2019/1/21.
//  Copyright © 2019年 ICE. All rights reserved.
//

#import "ViewController.h"
#import "BBImageManager.h"
#import "NSObject+BBImage.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *image_view;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)clickOn:(UIButton *)sender {
    NSString *link = @"http://img5.duitang.com/uploads/item/201411/07/20141107164412_v284V.jpeg";
    [BBImageManager.sharedManager imageFromUrl:link callback:^(UIImage *BBImage, NSString *md5, NSError *error) {
        if(error){NSLog(@"---%@---",error.domain);}
        else{
            self.image_view.image = BBImage;
        }
    }];
}

@end
