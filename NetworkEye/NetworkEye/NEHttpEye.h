//
//  NEHttpEye.h
//  NetworkEye
//
//  Created by coderyi on 15/11/3.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const NEHttpEyeSQLitePassword;
extern const NSInteger NEHttpEyeSaveRequestMaxCount;

@interface NEHttpEye : NSURLProtocol

/**
 *  open or close HTTP/HTTPS monitor
 *
 *  @param enabled
 */
+ (void)setEnabled:(BOOL)enabled;

/**
 *  display HTTP/HTTPS monitor state
 *
 *  @return HTTP/HTTPS monitor state
 */
+ (BOOL)isEnabled;

/// 流量
+ (double)flowCount;

@end

NS_ASSUME_NONNULL_END
