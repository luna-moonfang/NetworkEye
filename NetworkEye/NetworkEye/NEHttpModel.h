//
//  NEHttpModel.h
//  NetworkEye
//
//  Created by coderyi on 15/11/4.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NEHttpModel : NSObject

@property (nonatomic, strong) NSURLRequest *ne_request;
@property (nonatomic, strong) NSHTTPURLResponse *ne_response;
@property (nonatomic, assign) double myID;
@property (nonatomic, copy) NSString *startDateString;
@property (nonatomic, copy) NSString *endDateString;

// request
@property (nonatomic, copy) NSString *requestURLString;
@property (nonatomic, copy) NSString *requestCachePolicy; // ???: 为什么不直接用NSURLRequestCachePolicy枚举类型
@property (nonatomic, assign) double requestTimeoutInterval;
@property (nonatomic, nullable, copy) NSString *requestHTTPMethod;
@property (nonatomic, nullable, copy) NSString *requestAllHTTPHeaderFields;
@property (nonatomic, nullable, copy) NSString *requestHTTPBody;

// response
@property (nonatomic, nullable, copy) NSString *responseMIMEType;
@property (nonatomic, copy) NSString * responseExpectedContentLength; // ???: 用 string 是为了展示
@property (nonatomic, nullable, copy) NSString *responseTextEncodingName;
@property (nullable, nonatomic, copy) NSString *responseSuggestedFilename;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, nullable, copy) NSString *responseAllHeaderFields;

// JSONData
@property (nonatomic, copy) NSString *receiveJSONData;

// 时间指标
@property (nonatomic, strong) NSURLSessionTaskMetrics *metrics  API_AVAILABLE(ios(10.0));

// TODO: 使用map
@property (nonatomic, copy) NSString *mapPath;
@property (nonatomic, copy) NSString *mapJSONData;

@end

NS_ASSUME_NONNULL_END
