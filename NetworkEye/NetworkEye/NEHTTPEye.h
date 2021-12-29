//
//  NEHTTPEye.h
//  NetworkEye
//
//  Created by coderyi on 15/11/3.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSQLitePassword @"networkeye"
#define kSaveRequestMaxCount 300

NS_ASSUME_NONNULL_BEGIN

@interface NEHTTPEye : NSURLProtocol

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

@end

NS_ASSUME_NONNULL_END
