//
//  GPCPaymentManager.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCPaymentManager.h"
#import "UIAlertView+Blocks.h"
#import "PayPalMobile.h"

@interface GPCPaymentManager ()
@property UIAlertView *paymentAlertView;
@end

NSString * const kPayPalClientID = @"AaA5HxBf_ZXpaG1JDoYaSi3sl9KxhH9visChFhGG6hD82iDV8sZQr4zOm6WH";

NSString * const kReceiverEmail = @"allegllet.scherzand-facilitator@gmail.com";

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
        [_delegate willPaid];
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

#pragma mark - PayPalPaymentDelegate methods

- (void)payPalPaymentDidComplete:(PayPalPayment *)completedPayment
{
    [self verifyCompletedPayment:completedPayment];
    [_delegate didPaid];
}

- (void)payPalPaymentDidCancel
{
    [_delegate didCancel];
}

- (void)verifyCompletedPayment:(PayPalPayment *)completedPayment {
    // Send the entire confirmation dictionary
    /*
    NSData *confirmation = [NSJSONSerialization dataWithJSONObject:completedPayment.confirmation
                                                           options:0
                                                             error:nil];
    */
    // Send confirmation to your server; your server should verify the proof of payment
    // and give the user their goods or services. If the server is not reachable, save
    // the confirmation and try again later.
}


@end
