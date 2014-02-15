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
#import <AudioToolbox/AudioToolbox.h>
#import <AdSupport/AdSupport.h>
#import <ESTBeaconManager.h>
#import "UIAlertView+Blocks.h"
#import <AVFoundation/AVFoundation.h>
#import "AFNetworking.h"

static const NSInteger kBeaconMajorId = 6521;
static const NSInteger kBeaconMinorId = 13509;

@interface GPCViewController () <ESTBeaconManagerDelegate>

@property ESTBeaconManager          *beaconManager;
@property ESTBeacon                 *selectedBeacon;
@property NSTimer                   *delayedNotificationTimer;
@property NSTimer                   *delayedSoundTimer;
@property NSTimer                   *repeatSoundTimer;
@property UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property UIAlertView               *paymentAlertView;
@property BOOL                      isEnter;

@property (strong, nonatomic) IBOutlet UITextView *debugLogView;
@end

@implementation GPCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBeacon];
    /*
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    [manager POST:@"http://ancient-brushlands-9645.herokuapp.com/post" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
     */

}

- (void)setupBeacon
{
    _beaconManager = [[ESTBeaconManager alloc] init];
    [_beaconManager setDelegate:self];
    [_beaconManager setAvoidUnknownStateBeacons:YES];
    ESTBeaconRegion *region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                  identifier:@"jp.co.GeliPayClient.iBencon"];
#ifdef ONLY_FOREGROUND
    [_beaconManager startRangingBeaconsInRegion:region];
#else
    [_beaconManager startMonitoringForRegion:region];
    [_beaconManager requestStateForRegion:region];
#endif
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

static const CGFloat kPlaySoundDelayTime = 5.0f;
- (void)notifyAndStartCountDown
{
    _delayedSoundTimer = [NSTimer scheduledTimerWithTimeInterval:kPlaySoundDelayTime
                                                       target:self
                                                     selector:@selector(repeatsSound)
                                                     userInfo:nil repeats:NO];
    [self presentLocalNotification];
    [self showPaymentAlert];
}

- (void)showPaymentAlert
{
    RIButtonItem *paymentItem = [RIButtonItem itemWithLabel:@"Pay" action:^{
        [self payment];
    }];
    
    [self presentLocalNotification];
    
    _paymentAlertView = [[UIAlertView alloc] initWithTitle:@"GeliPay"
                                                   message:@"GeliPayしてください"
                                          cancelButtonItem:nil
                                          otherButtonItems:paymentItem, nil];
    [_paymentAlertView show];
}

- (void)presentLocalNotification
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    [localNotification setAlertBody:@"GeliPayしてください"];
    [localNotification setSoundName:UILocalNotificationDefaultSoundName];
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}

static const CGFloat kSoundRepetInterval = 2.0f;
- (void)repeatsSound
{
    _repeatSoundTimer = [NSTimer scheduledTimerWithTimeInterval:kSoundRepetInterval
                                                         target:self
                                                       selector:@selector(playSound)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)playSound
{
    AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    NSString* speakingText = @"私はトイレが長いです。";
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speakingText];
    [speechSynthesizer speakUtterance:utterance];

}

- (void)payment
{
    [self showLog:@">>>>> Paid"];
    [_delayedSoundTimer invalidate];
    [_repeatSoundTimer invalidate];
    
    [self endBackgroundTask];
}

- (void)startBackgroundTask
{
    _backgroundTaskIdentifier = [[UIApplication sharedApplication]beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask
{
    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskIdentifier];
}

- (NSString *)uniqueId
{
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

#pragma mark -Debug

- (void)showLog:(NSString *)log
{
    [_debugLogView setText:[[_debugLogView text] stringByAppendingString:[NSString stringWithFormat:@"%@\n", log]]];
    
}

- (IBAction)onDebugButtonTapped:(id)sender
{
    [self startBackgroundTask];
    [self onExitRegion];
}

#pragma mark - Estimote

- (void)beaconManager:(ESTBeaconManager *)manager
      didRangeBeacons:(NSArray *)beacons
             inRegion:(ESTBeaconRegion *)region
{
    static BOOL isEnter = NO;
    if([beacons count] > 0) {
        ESTBeacon *selectedBeacon = beacons[0];
        
        switch (selectedBeacon.proximity)
        {
            case CLProximityImmediate:
            if (!isEnter) {
                isEnter = YES;
                [self onEnterRegion];
            }
            break;
            default:
            if (isEnter) {
                isEnter = NO;
                [self onExitRegion];
            }
            break;
        }
    }
}

- (void)beaconManager:(ESTBeaconManager *)manager
    didDetermineState:(CLRegionState)state
            forRegion:(ESTBeaconRegion *)region
{
    if (state == CLRegionStateInside) {
        [self onEnterRegion];
    } else {
        [self onExitRegion];
    }
}

static const CGFloat kNotifyAndStartCountDownTime = 5.0f;
- (void)onEnterRegion
{
    
    [self showLog:@">>>>> onEnterRegion"];

    if (_isEnter) return;
    _isEnter = YES;
    
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
    [self startBackgroundTask];
    
    _delayedNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:kNotifyAndStartCountDownTime
                                                                 target:self
                                                               selector:@selector(notifyAndStartCountDown)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (void)onExitRegion
{
    [self showLog:@">>>>> onExitRegion"];
    
    if (!_isEnter) return;
    _isEnter = NO;
    
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
    [_repeatSoundTimer invalidate];
    
    [_paymentAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    [self endBackgroundTask];
}

@end
