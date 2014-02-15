//
//  GPCTimerObject.h
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^GPCExecutionBlock)();

@interface GPCCancelableDelayedExecution : NSObject

+ (void)executeBlock:(GPCExecutionBlock)block
          afterDelay:(NSTimeInterval)afterDelay;

+ (void)cancel;

@end
