//
//  GPCTimerObject.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCCancelableDelayedExecution.h"

@interface GPCCancelableDelayedExecution ()
@property (copy) GPCExecutionBlock block;
@end

@interface GPCCancelableDelayedExecution (Private)
- (void)executeBlock:(GPCExecutionBlock)block
          afterDelay:(NSTimeInterval)afterDelay;
- (void)execute;
- (void)cancel;
@end

static GPCCancelableDelayedExecution *instance;

@implementation GPCCancelableDelayedExecution

+ (void)initialize
{
    if (self == [GPCCancelableDelayedExecution class]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instance = [[self alloc] init];
        });
    }
}

+ (void)executeBlock:(GPCExecutionBlock)block
          afterDelay:(NSTimeInterval)afterDelay
{
    [instance executeBlock:block afterDelay:afterDelay];
}

+ (void)cancel
{
    [instance cancel];
}

@end

@implementation GPCCancelableDelayedExecution (Private)

- (void)executeBlock:(GPCExecutionBlock)block
           afterDelay:(NSTimeInterval)afterDelay
{
    NSAssert(!_block, @"Cancel previous execution.");
    
    [self setBlock:block];
    [self performSelector:@selector(execute)
               withObject:nil
               afterDelay:afterDelay];
}

- (void)execute
{
    _block();
}

- (void)cancel
{
    [self setBlock:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

@end
