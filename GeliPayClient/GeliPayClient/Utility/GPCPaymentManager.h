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

- (void)didCancel;

@end

@interface GPCPaymentManager : NSObject

@property (weak) id <GPCPaymentManagerDelegate> delegate;

+ (id)sharedInstance;

- (void)dismissPaymentAlert;

- (void)presentPaymentLocalNotification;

@end

FOUNDATION_EXTERN NSString * const kPayPalClientID;

FOUNDATION_EXTERN NSString * const kReceiverEmail;