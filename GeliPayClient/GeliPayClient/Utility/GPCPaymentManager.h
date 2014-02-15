//
//  GPCPaymentManager.h
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GPCPaymentManagerDelegate <NSObject>

- (void)didPaid;

@end

@interface GPCPaymentManager : NSObject

@property (weak) id <GPCPaymentManagerDelegate> delegate;

+ (id)sharedInstance;

- (void)notifyPaymentAfterDelay:(NSTimeInterval)afterDelay;

- (void)showPaymentAlert;

- (void)dismissPaymentAlert;

- (void)presentPaymentLocalNotification;

@end
