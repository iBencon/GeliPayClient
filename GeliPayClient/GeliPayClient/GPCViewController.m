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

static const NSInteger kBeaconMajorId = 6521;
static const NSInteger kBeaconMinorId = 13509;

@interface GPCViewController () <GPCBeaconUtilityDelegate, GPCPaymentManagerDelegate>

@property NSTimer                   *delayedNotificationTimer;
@property NSTimer                   *delayedSoundTimer;
@property UIAlertView               *paymentAlertView;

@property (strong, nonatomic) IBOutlet UITextView *debugLogView;
@end

@implementation GPCViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Start out working with the test environment! When you are ready, remove this line to switch to live.
    [PayPalPaymentViewController setEnvironment:PayPalEnvironmentNoNetwork];
    [PayPalPaymentViewController prepareForPaymentUsingClientId:@"YOUR_CLIENT_ID"];
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
    _delayedSoundTimer = [NSTimer scheduledTimerWithTimeInterval:kPlaySoundDelayTime
                                                       target:[GPCSoudPlayer sharedInstance]
                                                     selector:@selector(start)
                                                     userInfo:nil
                                                         repeats:NO];
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

#pragma mark - Estimote

static const CGFloat kNotifyAndStartCountDownTime = 5.0f;
- (void)onEnterRegion
{
    [self showLog:@">>>>> onEnterRegion"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"devise_id" : [NSString stringWithFormat:@"%ld-%ld", (long)kBeaconMajorId, (long)kBeaconMinorId],
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
                NSLog(@"response: %@", responseObject);
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@", error);
    }];
#endif
    [_delayedNotificationTimer invalidate];
    [_delayedSoundTimer invalidate];
    [[GPCPaymentManager sharedInstance] dismissPaymentAlert];
    [[GPCSoudPlayer sharedInstance] stop];
}

#pragma mark - Payment

-(void)willPaid
{
    // Create a PayPalPayment
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = [[NSDecimalNumber alloc] initWithString:@"39.95"];
    payment.currencyCode = @"USD";
    payment.shortDescription = @"下痢止め";
    
    // Check whether payment is processable.
    if (!payment.processable) {
        // If, for example, the amount was negative or the shortDescription was empty, then
        // this payment would not be processable. You would want to handle that here.
        NSLog(@"This payment would not be processable.");
    }
    
    [PayPalPaymentViewController setEnvironment:PayPalEnvironmentNoNetwork];
    
    // Provide a payerId that uniquely identifies a user within the scope of your system,
    // such as an email address or user ID.
    NSString *aPayerId = @"allegllet.scherzand.paypal@gmail.com";
    
    // Create a PayPalPaymentViewController with the credentials and payerId, the PayPalPayment
    // from the previous step, and a PayPalPaymentDelegate to handle the results.
    PayPalPaymentViewController *paymentViewController;
    paymentViewController = [[PayPalPaymentViewController alloc] initWithClientId:@"AaA5HxBf_ZXpaG1JDoYaSi3sl9KxhH9visChFhGG6hD82iDV8sZQr4zOm6WH"
                                                                    receiverEmail:@"allegllet.scherzand-facilitator@gmail.com"
                                                                          payerId:aPayerId
                                                                          payment:payment
                                                                         delegate:[GPCPaymentManager sharedInstance]];
    
    // Present the PayPalPaymentViewController.
    [self presentViewController:paymentViewController animated:YES completion:nil];
}

- (void)didPaid {
    [self showLog:@">>>>> Paid"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"devise_id" : [NSString stringWithFormat:@"%ld-%ld", (long)kBeaconMajorId, (long)kBeaconMinorId],
                            @"uid" : [GPCDeviceInformation uniqueID]};
    [manager POST:@"http://gelipay.herokuapp.com/users/pay.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
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
