//
//  NEMapViewController.h
//  NetworkEye
//
//  Created by coderyi on 16/9/25.
//  Copyright © 2016年 coderyi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEHTTPModel;
@interface NEMapViewController : UIViewController
@property (nonatomic,strong) NEHTTPModel *model;
@end

NS_ASSUME_NONNULL_END
