//
//  NEHttpModelManager.h
//  NetworkEye
//
//  Created by coderyi on 15/11/4.
//  Copyright © 2015年 coderyi. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NEHttpEye.h"

NS_ASSUME_NONNULL_BEGIN

@class NEHttpModel;

@interface NEHttpModelManager : NSObject {
    NSMutableArray *allRequests;
    BOOL enablePersistent;
}

@property (nonatomic, copy) NSString *sqlitePassword;
@property (nonatomic, assign) NSInteger saveRequestMaxCount;

/**
 *  get recorded requests 's SQLite filename
 *
 *  @return filename
 */
+ (NSString *)filename;

/**
 *  get NEHttpModelManager's singleton object
 *
 *  @return singleton object
 */
+ (NEHttpModelManager *)defaultManager;

/**
 *  create NEHttpModel table
 */
- (void)createTable;


/**
 *  add a NEHttpModel object to SQLite
 *
 *  @param aModel a NEHttpModel object
 */
- (void)addModel:(NEHttpModel *) aModel;

/**
 *  get SQLite all NEHttpModel object
 *
 *  @return all NEHttpModel object
 */
- (NSMutableArray *)allobjects;

/**
 *  delete all SQLite records
 */
- (void) deleteAllItem;

- (NSMutableArray *)allMapObjects;
- (void)addMapObject:(NEHttpModel *)mapReq;
- (void)removeMapObject:(NEHttpModel *)mapReq;
- (void)removeAllMapObjects;

@end

NS_ASSUME_NONNULL_END
