//
//  GPCViewController.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#define OFFLINE = 1
//#define ONLY_FOREGROUND = 1

#import "GPCViewController.h"
#import "AFNetworking.h"
#import "GPCSoudPlayer.h"
#import "GPCBeaconUtility.h"
#import "GPCPaymentManager.h"
#import "GPCBackgroundTaskManager.h"

static const NSInteger kBeaconMajorId = 6521;
static const NSInteger kBeaconMinorId = 13509;

@interface GPCViewController () <GPCBeaconUtilityDelegate, GPCPaymentManagerDelegate>

@property NSTimer                   *delayedNotificationTimer;
@property NSTimer                   *delayedSoundTimer;
@property UIAlertView               *paymentAlertView;

@property (strong, nonatomic) IBOutlet UITextView *debugLogView;
@end

@implementation GPCViewController

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
                            @"uid" : [self uniqueId]};
    [manager POST:@"http://gelipay.herokuapp.com/users.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
#endif
    
}

- (void)onExitRegion
{
    [self showLog:@">>>>> onExitRegion"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"uid" : [self uniqueId]};
    [manager DELETE:@"http://gelipay.herokuapp.com/users/exit.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
#endif
    [_delayedNotificationTimer invalidate];
    [_delayedSoundTimer invalidate];
    [[GPCSoudPlayer sharedInstance] stop];
}

#pragma mark - Payment

-(void)didPaid
{
    [self showLog:@">>>>> Paid"];
    [_delayedSoundTimer invalidate];
    [[GPCSoudPlayer sharedInstance] stop];
}

@end
