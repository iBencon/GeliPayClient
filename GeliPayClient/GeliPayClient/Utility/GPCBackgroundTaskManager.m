//
//  GPCBackgroundTaskManager.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCBackgroundTaskManager.h"

@interface GPCBackgroundTaskManager ()
@property UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@end

@implementation GPCBackgroundTaskManager

+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static GPCBackgroundTaskManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[GPCBackgroundTaskManager alloc] init];
    });
    return sharedInstance;
}

- (void)startBackgroundTask
{
    _backgroundTaskIdentifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
}

@end
