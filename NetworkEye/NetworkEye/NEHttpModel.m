//
//  NEHttpModel.m
//  NetworkEye
//
//  Created by coderyi on 15/11/4.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "NEHttpModel.h"

@implementation NEHttpModel

@synthesize ne_request, ne_response;

- (void)setNe_request:(NSURLRequest *)ne_request_new {
    ne_request = ne_request_new;
    
    self.requestURLString = ne_request.URL.absoluteString;
    
    switch (ne_request.cachePolicy) {
        case NSURLRequestUseProtocolCachePolicy:
            self.requestCachePolicy = @"NSURLRequestUseProtocolCachePolicy";
            break;
        case NSURLRequestReloadIgnoringLocalCacheData:
//        case NSURLRequestReloadIgnoringCacheData:
            self.requestCachePolicy = @"NSURLRequestReloadIgnoringLocalCacheData";
            break;
        case NSURLRequestReturnCacheDataElseLoad:
            self.requestCachePolicy = @"NSURLRequestReturnCacheDataElseLoad";
            break;
        case NSURLRequestReturnCacheDataDontLoad:
            self.requestCachePolicy = @"NSURLRequestReturnCacheDataDontLoad";
            break;
        case NSURLRequestReloadIgnoringLocalAndRemoteCacheData:
            self.requestCachePolicy = @"NSURLRequestReloadIgnoringLocalAndRemoteCacheData";
            break;
        case NSURLRequestReloadRevalidatingCacheData:
            self.requestCachePolicy = @"NSURLRequestReloadRevalidatingCacheData";
            break;
        default:
            self.requestCachePolicy=@"";
            break;
    }
    
    self.requestTimeoutInterval = [[NSString stringWithFormat:@"%.1lf", ne_request.timeoutInterval] doubleValue]; // ???: 取 1 位小数? 有必要?
    self.requestHTTPMethod = ne_request.HTTPMethod;
    
    for (NSString *key in ne_request.allHTTPHeaderFields.allKeys) {
        self.requestAllHTTPHeaderFields = [NSString stringWithFormat:@"%@%@", self.requestAllHTTPHeaderFields, [self formateRequestHeaderFieldKey:key object:ne_request.allHTTPHeaderFields[key]]];
    }
    
    [self appendCookieStringAfterRequestAllHTTPHeaderFields];
    
    if (self.requestAllHTTPHeaderFields.length > 1) {
        if ([[self.requestAllHTTPHeaderFields substringFromIndex:self.requestAllHTTPHeaderFields.length - 1] isEqualToString:@"\n"]) {
            self.requestAllHTTPHeaderFields = [self.requestAllHTTPHeaderFields substringToIndex:self.requestAllHTTPHeaderFields.length - 1];
        }
    }
    
    if (self.requestAllHTTPHeaderFields.length > 6) {
        if ([[self.requestAllHTTPHeaderFields substringToIndex:6] isEqualToString:@"(null)"]) {
            self.requestAllHTTPHeaderFields = [self.requestAllHTTPHeaderFields substringFromIndex:6];
        }
    }
    
    if (ne_request.HTTPBody.length > 512) {
        self.requestHTTPBody = @"requestHTTPBody too long";
    } else {
        if ([ne_request.HTTPMethod isEqualToString:@"POST"] &&
            !ne_request.HTTPBody) {
            uint8_t rd[1024] = {0};
            NSInputStream *stream = ne_request.HTTPBodyStream;
            NSMutableData *data = [[NSMutableData alloc] init];
            [stream open];
            while ([stream hasBytesAvailable]) {
                NSInteger len = [stream read:rd maxLength:1024];
                if (len > 0 && stream.streamError == nil) {
                    [data appendBytes:(void *)rd length:len];
                }
            }
            self.requestHTTPBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [stream close];
        } else {
            self.requestHTTPBody = [[NSString alloc] initWithData:ne_request.HTTPBody encoding:NSUTF8StringEncoding];
        }
    }
    
    if (self.requestHTTPBody.length > 1) {
        if ([[self.requestHTTPBody substringFromIndex:self.requestHTTPBody.length - 1] isEqualToString:@"\n"]) {
            self.requestHTTPBody = [self.requestHTTPBody substringToIndex:self.requestHTTPBody.length - 1];
        }
    }
}

- (void)setNe_response:(NSHTTPURLResponse *)ne_response_new {
    ne_response = ne_response_new;
    
    self.responseMIMEType = @"";
    self.responseExpectedContentLength = @"";
    self.responseTextEncodingName = @"";
    self.responseSuggestedFilename = @"";
    self.responseStatusCode = 200;
    self.responseAllHeaderFields = @"";
    
    self.responseMIMEType = ne_response.MIMEType;
    self.responseExpectedContentLength = [NSString stringWithFormat:@"%lld", ne_response.expectedContentLength];
    self.responseTextEncodingName = ne_response.textEncodingName;
    self.responseSuggestedFilename = ne_response.suggestedFilename;
    self.responseStatusCode = ne_response.statusCode;
    
    for (NSString *key in ne_response.allHeaderFields.allKeys) {
        NSString *headerFieldValue = ne_response.allHeaderFields[key];
        if ([key isEqualToString:@"Content-Security-Policy"]) {
            if (headerFieldValue.length > 12 &&
                [[headerFieldValue substringFromIndex:12] isEqualToString:@"'none'"]) {
                headerFieldValue = [headerFieldValue substringToIndex:11];
            }
        }
        self.responseAllHeaderFields = [NSString stringWithFormat:@"%@%@:%@\n", self.responseAllHeaderFields, key, headerFieldValue];
    }
    
    if (self.responseAllHeaderFields.length > 1) {
        if ([[self.responseAllHeaderFields substringFromIndex:self.responseAllHeaderFields.length-1] isEqualToString:@"\n"]) {
            self.responseAllHeaderFields = [self.responseAllHeaderFields substringToIndex:self.responseAllHeaderFields.length - 1];
        }
    }
}

- (void)appendCookieStringAfterRequestAllHTTPHeaderFields {
    NSString *host = self.ne_request.URL.host;
    NSArray *cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies;
    NSMutableArray *cookieValues = [NSMutableArray array];
    for (NSHTTPCookie *cookie in cookies) {
        NSString *domain = [cookie.properties valueForKey:NSHTTPCookieDomain];
        NSRange range = [host rangeOfString:domain];
        NSComparisonResult result = [cookie.expiresDate compare:[NSDate date]];
        
        if (range.location != NSNotFound && result == NSOrderedDescending) {
            [cookieValues addObject:[NSString stringWithFormat:@"%@=%@", cookie.name, cookie.value]];
        }
    }
    
    if (cookieValues.count > 0) {
        NSString *cookieString = [cookieValues componentsJoinedByString:@";"];
        
        self.requestAllHTTPHeaderFields = [self.requestAllHTTPHeaderFields stringByAppendingString:[self formateRequestHeaderFieldKey:@"Cookie" object:cookieString]];
    }
}

- (NSString *)formateRequestHeaderFieldKey:(NSString *)key object:(id)obj {
    return [NSString stringWithFormat:@"%@:%@\n", key ?: @"", obj ?: @""];
}

@end
