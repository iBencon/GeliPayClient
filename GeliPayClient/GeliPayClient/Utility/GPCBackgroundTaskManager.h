//
//  GPCBackgroundTaskManager.h
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPCBackgroundTaskManager : NSObject

+ (id)sharedInstance;

- (void)startBackgroundTask;

- (void)endBackgroundTask;

@end
