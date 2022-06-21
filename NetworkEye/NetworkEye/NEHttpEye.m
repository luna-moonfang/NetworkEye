//
//  NEHttpEye.m
//  NetworkEye
//
//  Created by coderyi on 15/11/3.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "NEHttpEye.h"

#import "NEHttpModel.h"
#import "NEHttpModelManager.h"
#import "UIWindow+NEExtension.h"
#import "NEURLSessionConfiguration.h"
#import "NEKeyboardShortcutManager.h"
#import "NEHTTPEyeViewController.h"

NSString *const NEHttpEyeSQLitePassword = @"networkeye";
const NSInteger NEHttpEyeSaveRequestMaxCount = 300;

static NSString *const kEyeEnabledKey = @"NetworkEye.enabled";
static NSString *const kRequestHandledKey = @"NetworkEye.handled";
static NSString *const kFlowCountKey = @"NetworkEye.flowCount";

// use NSURLConnection or NSURLSession
static const BOOL kUseConnection = NO;


@interface NEHttpEye () <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;

@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSDate *startDate;

@property (nonatomic, strong) NEHttpModel *ne_httpModel;

@end


@implementation NEHttpEye

@synthesize ne_httpModel;

#pragma mark - Public

+ (void)setEnabled:(BOOL)enabled {
    [NSUserDefaults.standardUserDefaults setBool:enabled forKey:kEyeEnabledKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    
    NEURLSessionConfiguration *sessionConfiguration = [NEURLSessionConfiguration defaultConfiguration];
    
    if (enabled) {
        [NSURLProtocol registerClass:[NEHttpEye class]];
        if (!sessionConfiguration.swizzled) {
            [sessionConfiguration load];
        }
    } else {
        [NSURLProtocol unregisterClass:[NEHttpEye class]];
        if (sessionConfiguration.swizzled) {
            [sessionConfiguration unload];
        }
    }
    
    // TODO: 模拟器或键盘快捷键
#if TARGET_OS_SIMULATOR
    [NEKeyboardShortcutManager sharedManager].enabled = enabled;
    [[NEKeyboardShortcutManager sharedManager] registerSimulatorShortcutWithKey:@"n" modifiers:UIKeyModifierCommand action:^{
        NEHTTPEyeViewController *viewController = [[NEHTTPEyeViewController alloc] init];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:viewController animated:YES completion:nil];
    } description:nil];
#endif
}

+ (BOOL)isEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:kEyeEnabledKey];
}

+ (CGFloat)flowCount {
    return [NSUserDefaults.standardUserDefaults doubleForKey:kFlowCountKey];
}

#pragma mark - NSURLProtocol Override

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    if ([NSURLProtocol propertyForKey:kRequestHandledKey inRequest:request] ) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kRequestHandledKey inRequest:mutableReqeust];
    return [mutableReqeust copy];
}

- (void)startLoading {
    self.startDate = [NSDate date];
    self.data = [NSMutableData data];
    
    NSURLRequest *request = [[self class] canonicalRequestForRequest:self.request];
    if (kUseConnection) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
#pragma clang diagnostic pop
    } else {
        NSURLSessionConfiguration *configuration = NSURLSessionConfiguration.defaultSessionConfiguration;
        // ???: 打断点看 delegate 方法是否触发? 此时 queue 是什么?
        self.session = [NSURLSession sessionWithConfiguration:configuration];
        self.dataTask = [self.session dataTaskWithRequest:request];
        [self.dataTask resume];
    }
    
    ne_httpModel = [[NEHttpModel alloc] init];
    ne_httpModel.ne_request = self.request;
    ne_httpModel.startDateString = [self stringWithDate:[NSDate date]];
    
    // ???: 直接用时间戳代替
    NSTimeInterval myID = [NSDate date].timeIntervalSince1970; // 单位s or ms?
    double randomNum = ((double)(arc4random() % 100)) / 10000; // 0~99随机数/10000 = 0.0001~0.01
    ne_httpModel.myID = myID + randomNum;
}

- (void)stopLoading {
    if (kUseConnection) {
        [self.connection cancel];
    } else {
        [self.dataTask cancel];
    }
    
    ne_httpModel.ne_response = (NSHTTPURLResponse *)self.response;
    ne_httpModel.endDateString = [self stringWithDate:[NSDate date]];
    
    NSString *mimeType = self.response.MIMEType;
    
    if ([mimeType isEqualToString:@"application/json"]) {
        ne_httpModel.receiveJSONData = [self responseJSONFromData:self.data];
    } else if ([mimeType isEqualToString:@"text/javascript"]) {
        // try to parse json if it is jsonp request
        NSString *jsonString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
        // formalize string
        if ([jsonString hasSuffix:@")"]) {
            jsonString = [NSString stringWithFormat:@"%@;", jsonString];
        }
        if ([jsonString hasSuffix:@");"]) {
            NSRange range = [jsonString rangeOfString:@"("];
            if (range.location != NSNotFound) {
                range.location++;
                range.length = [jsonString length] - range.location - 2; // removes parens and trailing semicolon
                jsonString = [jsonString substringWithRange:range];
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
                ne_httpModel.receiveJSONData = [self responseJSONFromData:jsonData];
            }
        }
    } else if ([mimeType isEqualToString:@"application/xml"] ||
               [mimeType isEqualToString:@"text/xml"]) {
        NSString *xmlString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
        if (xmlString && xmlString.length > 0) {
            ne_httpModel.receiveJSONData = xmlString; // example http://webservice.webxml.com.cn/webservices/qqOnlineWebService.asmx/qqCheckOnline?qqCode=2121
        }
    }
    
    double flowCount = [NSUserDefaults.standardUserDefaults doubleForKey:kFlowCountKey];
    flowCount += self.response.expectedContentLength / (1024.0 * 1024.0);
    
    [NSUserDefaults.standardUserDefaults setDouble:flowCount forKey:kFlowCountKey];
    [NSUserDefaults.standardUserDefaults synchronize]; // https://github.com/coderyi/NetworkEye/pull/6
    
    [[NEHttpModelManager defaultManager] addModel:ne_httpModel];
}

#pragma mark - NSURLConnection
#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    [[self client] URLProtocol:self didFailWithError:error];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    return YES;
}

- (void)connection:(NSURLConnection *)connection
didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[self client] URLProtocol:self didReceiveAuthenticationChallenge:challenge];
}

- (void)connection:(NSURLConnection *)connection
didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    [[self client] URLProtocol:self didCancelAuthenticationChallenge:challenge];
}

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response != nil){
        self.response = response;
        [[self client] URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    return request;
}

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    self.response = response;
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data {
    NSString *mimeType = self.response.MIMEType;
    if ([mimeType isEqualToString:@"application/json"]) {
        NSArray *allMapRequests = [[NEHttpModelManager defaultManager] allMapObjects];
        for (NSInteger i=0; i < allMapRequests.count; i++) {
            NEHttpModel *req = [allMapRequests objectAtIndex:i];
            if ([[ne_httpModel.ne_request.URL absoluteString] containsString:req.mapPath]) {
                NSData *jsonData = [req.mapJSONData dataUsingEncoding:NSUTF8StringEncoding];
                [[self client] URLProtocol:self didLoadData:jsonData];
                [self.data appendData:jsonData];
                return;
                
            }
        }
    }
    [[self client] URLProtocol:self didLoadData:data];
    [self.data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[self client] URLProtocolDidFinishLoading:self];
}

#pragma mark - Utils

- (id)responseJSONFromData:(NSData *)data {
    if (data == nil) {
        return nil;
    }
    
    NSError *error = nil;
    id returnValue = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        NSLog(@"JSON Parsing Error: %@", error); // https://github.com/coderyi/NetworkEye/issues/3
        return nil;
    }
    
    // https://github.com/coderyi/NetworkEye/issues/1
    if (!returnValue || returnValue == [NSNull null]) {
        return nil;
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:returnValue options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

- (NSString *)stringWithDate:(NSDate *)date {
    NSString *destDateString = [[NEHttpEye defaultDateFormatter] stringFromDate:date];
    return destDateString;
}

+ (NSDateFormatter *)defaultDateFormatter {
    static NSDateFormatter *staticDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticDateFormatter = [[NSDateFormatter alloc] init];
        staticDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss zzz"; // zzz表示时区，zzz可以删除，这样返回的日期字符将不包含时区信息。
    });
    return staticDateFormatter;
}

@end
