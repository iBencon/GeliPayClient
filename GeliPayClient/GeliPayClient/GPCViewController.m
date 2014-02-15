//
//  GPCViewController.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

//#define OFFLINE = 1
#define ONLY_FOREGROUND = 1

#import "GPCViewController.h"
#import "AFNetworking.h"
#import "GPCSoudPlayer.h"
#import "GPCBeaconUtility.h"
#import "GPCPaymentManager.h"
#import "GPCBackgroundTaskManager.h"
#import "GPCDeviceInformation.h"
#import "PayPalMobile.h"
#import "GPCCountDownTimer.h"

@interface GPCViewController () <GPCBeaconUtilityDelegate, GPCPaymentManagerDelegate, GPCCountDownTimerDelegate>

@property NSTimer                   *delayedNotificationTimer;
@property NSTimer                   *delayedSoundTimer;
@property UIAlertView               *paymentAlertView;

@property (strong, nonatomic) IBOutlet UITextView *debugLogView;
@end

@implementation GPCViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [PayPalPaymentViewController setEnvironment:PayPalEnvironmentNoNetwork];
    [PayPalPaymentViewController prepareForPaymentUsingClientId:kPayPalClientID];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[GPCBeaconUtility sharedInstance] setDelegate:self];
    [[GPCPaymentManager sharedInstance] setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

static const CGFloat kPlaySoundDelayTime = 5.0f;
- (void)notifyAndPlaySoundAfterDelay
{
    [[GPCCountDownTimer sharedInstance] executeBlock:^{
        [[GPCSoudPlayer sharedInstance] startRepeat];
    }
                                          afterDelay:kPlaySoundDelayTime
                                            delegate:self];
    [[GPCPaymentManager sharedInstance] presentPaymentLocalNotification];
    [[GPCPaymentManager sharedInstance] showPaymentAlert];
}

#pragma mark -Debug

- (void)showLog:(NSString *)log
{
    [_debugLogView setText:[[_debugLogView text] stringByAppendingString:[NSString stringWithFormat:@"%@\n", log]]];
    
}

- (IBAction)onDebugButtonTapped:(id)sender
{
    [[GPCBackgroundTaskManager sharedInstance] startBackgroundTask];
    [self onExitRegion];
}

#pragma mark - Countdown Timer Delegate

- (void)onUpdateTime:(NSTimeInterval)restTime
{
    NSLog(@"%f", restTime);
}

#pragma mark - Estimote Delegate

static const CGFloat kNotifyAndStartCountDownTime = 5.0f;
- (void)onEnterRegion:(ESTBeaconRegion *)region
{
    [self showLog:@">>>>> onEnterRegion"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"devise_id" : [NSString stringWithFormat:@"%@-%@", [region major], [region minor]],
                            @"uid" : [GPCDeviceInformation uniqueID]};
    [manager POST:@"http://gelipay.herokuapp.com/users.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
#endif
    
    _delayedNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:kNotifyAndStartCountDownTime
                                                                 target:self
                                                               selector:@selector(notifyAndPlaySoundAfterDelay)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (void)onExitRegion
{
    [self showLog:@">>>>> onExitRegion"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"uid" : [GPCDeviceInformation uniqueID]};
    [manager DELETE:@"http://gelipay.herokuapp.com/users/exit.json"
         parameters:param
            success:^(AFHTTPRequestOperation *operation, id responseObject)
            {
                NSLog(@">>>>> Response: %@", responseObject);
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@">>>>> Error: %@", error);
    }];
#endif
    [_delayedNotificationTimer invalidate];
    [_delayedSoundTimer invalidate];
    [[GPCPaymentManager sharedInstance] dismissPaymentAlert];
    [[GPCSoudPlayer sharedInstance] stop];
}

#pragma mark - Payment Delegate

-(void)willPaid
{
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = [[NSDecimalNumber alloc] initWithString:@"39.95"];
    payment.currencyCode = @"USD";
    payment.shortDescription = @"下痢止め";
    
    if (!payment.processable) {
        NSLog(@"This payment would not be processable.");
    }
    
    [PayPalPaymentViewController setEnvironment:PayPalEnvironmentNoNetwork];
    
    NSString *aPayerId = @"allegllet.scherzand.paypal@gmail.com";
    
    PayPalPaymentViewController *paymentViewController;
    paymentViewController = [[PayPalPaymentViewController alloc] initWithClientId:kPayPalClientID
                                                                    receiverEmail:kReceiverEmail
                                                                          payerId:aPayerId
                                                                          payment:payment
                                                                         delegate:[GPCPaymentManager sharedInstance]];
    
    [self presentViewController:paymentViewController animated:YES completion:nil];
}

- (void)didPaid
{
    [self showLog:@">>>>> Paid"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"devise_id" : [NSString stringWithFormat:@"%d-%d", kBeaconMajorID, kBeaconMinorID],
                            @"uid" : [GPCDeviceInformation uniqueID]};
    [manager POST:@"http://gelipay.herokuapp.com/users/pay.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@">>>>> Response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@">>>>> Error: %@", error);
    }];
#endif
    [_delayedSoundTimer invalidate];
    [[GPCSoudPlayer sharedInstance] stop];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didCancel
{
    [self dismissViewControllerAnimated:YES completion:^{
        [[GPCPaymentManager sharedInstance] showPaymentAlert];
    }];
}


@end
