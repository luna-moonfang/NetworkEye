//
//  NEHTTPEyeDetailViewController.h
//  NetworkEye
//
//  Created by coderyi on 15/11/4.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NEHTTPModel;

@interface NEHTTPEyeDetailViewController : UIViewController
/**
 *  detail page's data model,about request,response and data
 */
@property (nonatomic,strong) NEHTTPModel *model;

@end

NS_ASSUME_NONNULL_END
