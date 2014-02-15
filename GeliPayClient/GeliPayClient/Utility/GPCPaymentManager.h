//
//  GPCPaymentManager.h
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GPCPaymentManagerDelegate <NSObject>

- (void)willPaid;

- (void)didPaid;

- (void)didCancel;

@end

@interface GPCPaymentManager : NSObject

@property (weak) id <GPCPaymentManagerDelegate> delegate;

+ (id)sharedInstance;

- (void)showPaymentAlert;

- (void)dismissPaymentAlert;

- (void)presentPaymentLocalNotification;

@end
