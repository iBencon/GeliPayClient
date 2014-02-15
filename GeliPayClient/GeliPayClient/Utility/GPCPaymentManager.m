//
//  GPCPaymentManager.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCPaymentManager.h"
#import "UIAlertView+Blocks.h"

@interface GPCPaymentManager ()
@property UIAlertView *paymentAlertView;
@end

@implementation GPCPaymentManager

+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static GPCPaymentManager *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[GPCPaymentManager alloc] init];
    });
    return sharedInstance;
}

- (void)showPaymentAlert
{
    RIButtonItem *paymentItem = [RIButtonItem itemWithLabel:@"Pay" action:^{
        [_delegate didPaid];
    }];
    
    _paymentAlertView = [[UIAlertView alloc] initWithTitle:@"GeliPay"
                                                   message:@"GeliPayしてください"
                                          cancelButtonItem:nil
                                          otherButtonItems:paymentItem, nil];
    [_paymentAlertView show];
}

- (void)dismissPaymentAlert
{
    [_paymentAlertView dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)presentPaymentLocalNotification
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    [localNotification setAlertBody:@"GeliPayしてください"];
    [localNotification setSoundName:UILocalNotificationDefaultSoundName];
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

@end
