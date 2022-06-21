//
//  NEHttpModelManager.m
//  NetworkEye
//
//  Created by coderyi on 15/11/4.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import "NEHttpModelManager.h"

#import "NEHttpModel.h"

#import "NEShakeGestureManager.h"

#if FMDB_SQLCipher
#include "sqlite3.h"
#import "FMDB.h"
#endif

static NSString *const kSQLiteFilename = @"networkeye.sqlite";
static NSString *const kTableName = @"networkeyerequests";
static NSString *const kCreateTableFormat = @"create table if not exists %@(myID double primary key,startDateString text,endDateString text,requestURLString text,requestCachePolicy text,requestTimeoutInterval double,requestHTTPMethod text,requestAllHTTPHeaderFields text,requestHTTPBody text,responseMIMEType text,responseExpectedContentLength text,responseTextEncodingName text,responseSuggestedFilename text,responseStatusCode int,responseAllHeaderFields text,receiveJSONData text);";

static NSString *const kCacheMaxKey = @"networkeye.cashMax";

static NSString *const kSTRDoubleMarks = @"\"";
static NSString *const kSQLDoubleMarks = @"\"\"";
static NSString *const kSTRShortMarks = @"'";
static NSString *const kSQLShortMarks = @"''";


@interface NEHttpModelManager() {
    NSMutableArray *allMapRequests;
#if FMDB_SQLCipher
    FMDatabaseQueue *sqliteDatabase;
#endif
}

@end

@implementation NEHttpModelManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _sqlitePassword = NEHttpEyeSQLitePassword;
        _saveRequestMaxCount = NEHttpEyeSaveRequestMaxCount;
        allRequests = [NSMutableArray arrayWithCapacity:1];
        allMapRequests = [NSMutableArray arrayWithCapacity:1];
        
        // TODO: 也可以有别的持久化方案, 例如TigerTrade用归档
#if FMDB_SQLCipher
        enablePersistent = YES;
#else
        enablePersistent = NO;
#endif
    }
    return self;
}

+ (NEHttpModelManager *)defaultManager {
    static NEHttpModelManager *staticManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticManager = [[NEHttpModelManager alloc] init];
        [staticManager createTable];
    });
    return staticManager;
}

+ (NSString *)filename {
    // 在 document 目录?
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths[0];
    NSString *string = [[NSString alloc] initWithFormat:@"%@/%@", documentsDirectory, kSQLiteFilename];
    return string;
}

- (void)createTable {
#if FMDB_SQLCipher
    NSString *sql = [NSString stringWithFormat:kCreateTableFormat, kTableName];
    FMDatabaseQueue *queue= [FMDatabaseQueue databaseQueueWithPath:[NEHttpModelManager filename]];
    [queue inDatabase:^(FMDatabase *db) {
        [db setKey:self.sqlitePassword];
        [db executeUpdate:sql];
    }];
#endif
}

- (void)addModel:(NEHttpModel *)aModel {
    if ([aModel.responseMIMEType isEqualToString:@"text/html"]) {
        aModel.receiveJSONData = @"";
    }
    
    if ([NSUserDefaults.standardUserDefaults boolForKey:kCacheMaxKey]) {
        // 保存的请求数达到最大
        [self deleteAllItem];
        [NSUserDefaults.standardUserDefaults setBool:NO forKey:kCacheMaxKey];
    }
    
    if (aModel.receiveJSONData == nil) {
        aModel.receiveJSONData = @"";
    }
    
    if (enablePersistent) {
#if FMDB_SQLCipher
        NSString *receiveJSONData = [self stringToSQLFilter:aModel.receiveJSONData];
        NSString *sql = [NSString stringWithFormat:@"insert into %@ values('%lf','%@','%@','%@','%@','%lf','%@','%@','%@','%@','%@','%@','%@','%ld','%@','%@')", kTableName, aModel.myID, aModel.startDateString, aModel.endDateString, aModel.requestURLString, aModel.requestCachePolicy, aModel.requestTimeoutInterval, aModel.requestHTTPMethod, aModel.requestAllHTTPHeaderFields, aModel.requestHTTPBody, aModel.responseMIMEType, aModel.responseExpectedContentLength, aModel.responseTextEncodingName, aModel.responseSuggestedFilename, aModel.responseStatusCode, [self stringToSQLFilter:aModel.responseAllHeaderFields], receiveJSONData];
        
        FMDatabaseQueue *queue= [FMDatabaseQueue databaseQueueWithPath:[NEHttpModelManager filename]];
        [queue inDatabase:^(FMDatabase *db) {
            [db setKey:self.sqlitePassword];
            [db executeUpdate:sql];
        }];
#endif
    } else {
        [allRequests addObject:aModel];
    }
}

- (NSMutableArray *)allobjects {
    if (!enablePersistent) {
        if (allRequests.count >= self.saveRequestMaxCount) {
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:kCacheMaxKey];
        }
        return allRequests;
    }
    
#if FMDB_SQLCipher
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[NEHttpModelManager filename]];
    NSString *sql = [NSString stringWithFormat:@"select * from %@ order by myID desc", kTableName];
    NSMutableArray *array = [NSMutableArray array];
    [queue inDatabase:^(FMDatabase *db) {
        [db setKey:self.sqlitePassword];
        FMResultSet *rs = [db executeQuery:sql];
        
        while ([rs next]) {
            NEHttpModel *model = [[NEHttpModel alloc] init];
            
            model.myID = [rs doubleForColumn:@"myID"];
            model.startDateString = [rs stringForColumn:@"startDateString"];
            model.endDateString = [rs stringForColumn:@"endDateString"];
            model.requestURLString = [rs stringForColumn:@"requestURLString"];
            model.requestCachePolicy = [rs stringForColumn:@"requestCachePolicy"];
            model.requestTimeoutInterval = [rs doubleForColumn:@"requestTimeoutInterval"];
            model.requestHTTPMethod = [rs stringForColumn:@"requestHTTPMethod"];
            model.requestAllHTTPHeaderFields = [rs stringForColumn:@"requestAllHTTPHeaderFields"];
            model.requestHTTPBody = [rs stringForColumn:@"requestHTTPBody"];
            model.responseMIMEType = [rs stringForColumn:@"responseMIMEType"];
            model.responseExpectedContentLength = [rs stringForColumn:@"responseExpectedContentLength"];
            model.responseTextEncodingName = [rs stringForColumn:@"responseTextEncodingName"];
            model.responseSuggestedFilename = [rs stringForColumn:@"responseSuggestedFilename"];
            model.responseStatusCode = [rs intForColumn:@"responseStatusCode"];
            model.responseAllHeaderFields = [self stringToSQLFilter:[rs stringForColumn:@"responseAllHeaderFields"]];
            model.receiveJSONData = [self stringToOBJFilter:[rs stringForColumn:@"receiveJSONData"]];
            
            [array addObject:model];
        }
    }];
    
    if (array.count >= self.saveRequestMaxCount) {
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:kCacheMaxKey];
    }
    
    return array;
#endif
    
    return nil;
}

- (void) deleteAllItem {
    if (!enablePersistent) {
        [allRequests removeAllObjects];
        return;
    }
    
#if FMDB_SQLCipher
    NSString *sql = [NSString stringWithFormat:@"delete from %@", kTableName];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[NEHttpModelManager filename]];
    [queue inDatabase:^(FMDatabase *db) {
        [db setKey:_sqlitePassword];
        [db executeUpdate:sql];
    }];
#endif
}

#pragma mark - Map

- (NSMutableArray *)allMapObjects {
    return allMapRequests;
}

- (void)addMapObject:(NEHttpModel *)mapReq {
    for (NSInteger i = 0; i < allMapRequests.count; i++) {
        NEHttpModel *req = allMapRequests[i];
        // ???: 写反了
//        if (![mapReq.mapPath isEqualToString:req.mapPath]) {
        if ([mapReq.mapPath isEqualToString:req.mapPath]) {
            [allMapRequests replaceObjectAtIndex:i withObject:mapReq];
            return;
        }
    }
    [allMapRequests addObject:mapReq];
}

- (void)removeMapObject:(NEHttpModel *)mapReq {
    for (NSInteger i = 0; i < allMapRequests.count; i++) {
        NEHttpModel *req = allMapRequests[i];
        if ([mapReq.mapPath isEqualToString:req.mapPath]) {
            [allMapRequests removeObject:mapReq];
            return;
        }
    }
}

- (void)removeAllMapObjects {
    [allMapRequests removeAllObjects];
}

#pragma mark - Utils

- (id)stringToSQLFilter:(id)string {
    if ([string isKindOfClass:[NSString class]]) {
        NSString *temp = string;
        // 从 string 到 SQL: 单引号 "'" 替换为 "''", 双引号 "\"" 替换为 "\"\""
        temp = [temp stringByReplacingOccurrencesOfString:kSTRShortMarks withString:kSQLShortMarks];
        temp = [temp stringByReplacingOccurrencesOfString:kSTRDoubleMarks withString:kSQLDoubleMarks];
        return temp;
    }
    return string;
}

- (id)stringToOBJFilter:(id)string {
    if ([string isKindOfClass:[NSString class]]) {
        NSString *temp = string;
        // 从 SQL 到 string: 单引号 "''" 替换为 "'", 双引号 "\"\"" 替换为 "\""
        temp = [temp stringByReplacingOccurrencesOfString:kSQLShortMarks withString:kSTRShortMarks];
        temp = [temp stringByReplacingOccurrencesOfString:kSQLDoubleMarks withString:kSTRDoubleMarks];
        return temp;
    }
    return string;
}

@end
