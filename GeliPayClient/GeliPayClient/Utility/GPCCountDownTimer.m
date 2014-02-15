//
//  GPCCountDownTimer.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/16.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCCountDownTimer.h"

@interface GPCCountDownTimer ()

@property (copy) GPCCountDownTimerExecuteBlock executeBlock;

@property NSTimer           *updateTimer;
@property NSDate            *startDate;
@property NSTimeInterval    afterDelay;

@end

@implementation GPCCountDownTimer

+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static GPCCountDownTimer *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[GPCCountDownTimer alloc] init];
    });
    return sharedInstance;
}


NSTimeInterval kUpdateTimeInterval = 0.5f;
- (void)executeBlock:(GPCCountDownTimerExecuteBlock)executeBlock
          afterDelay:(NSTimeInterval)afterDelay
            delegate:(id<GPCCountDownTimerDelegate>)delegate
{
    [self setExecuteBlock:executeBlock];
    _startDate = [NSDate date];
    _afterDelay = afterDelay;
    [self setDelegate:delegate];
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:kUpdateTimeInterval
                                                       target:self
                                                    selector:@selector(update)
                                                     userInfo:nil
                                                   repeats:YES];
}

- (void)update
{
    if ([self restTime] > 0) {
        [_delegate onUpdateTime:[self restTime]];
    } else {
        [_updateTimer invalidate];
        [self execute];
    }
}

- (void)cancel
{
    [_updateTimer invalidate];
}

- (void)execute
{
    _executeBlock();
    [self setExecuteBlock:nil];
}

- (NSTimeInterval)restTime
{
    return _afterDelay - [[NSDate date] timeIntervalSinceDate:_startDate];
}

@end
