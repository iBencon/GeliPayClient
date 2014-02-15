//
//  GPCCountDownTimer.h
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/16.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^GPCCountDownTimerExecuteBlock )();

@protocol GPCCountDownTimerDelegate <NSObject>

- (void)onUpdateTime:(NSTimeInterval)restTime;

@end

@interface GPCCountDownTimer : NSObject

@property (weak) id <GPCCountDownTimerDelegate> delegate;

+ (id)sharedInstance;

- (void)executeBlock:(GPCCountDownTimerExecuteBlock)executeBlock
          afterDelay:(NSTimeInterval)afterDelay
            delegate:(id<GPCCountDownTimerDelegate>)delegate;

- (void)cancel;

@end
