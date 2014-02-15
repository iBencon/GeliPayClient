//
//  GPCViewController.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AdSupport/AdSupport.h>
#import <ESTBeaconManager.h>
#import "UIAlertView+Blocks.h"
#import <AVFoundation/AVFoundation.h>

@interface GPCViewController () <ESTBeaconManagerDelegate>

@property ESTBeaconManager          *beaconManager;
@property ESTBeacon                 *selectedBeacon;
@property NSTimer                   *delayedNotificationTimer;
@property NSTimer                   *delayedSoundTimer;
@property NSTimer                   *repeatSoundTimer;
@property UIBackgroundTaskIdentifier backgroundTaskIdentifier;
@property UIAlertView               *paymentAlertView;

@property (strong, nonatomic) IBOutlet UITextView *debugLogView;

@end

@implementation GPCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBeacon];
    
    NSString *advertisingID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
    NSLog(@">>>>> UUID is ... %@", advertisingID);
}

- (void)setupBeacon
{
    _beaconManager = [[ESTBeaconManager alloc] init];
    [_beaconManager setDelegate:self];
    [_beaconManager setAvoidUnknownStateBeacons:YES];
    ESTBeaconRegion *region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                                       major:6521
                                                                       minor:13509
                                                                  identifier:@"jp.co.GeliPayClient.iBencon"];
    [_beaconManager startMonitoringForRegion:region];
    [_beaconManager requestStateForRegion:region];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

static const CGFloat kPlaySoundDelayTime = 10.0f;
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

#pragma mark -Debug

- (void)showLog:(NSString *)log
{
    [_debugLogView setText:[[_debugLogView text] stringByAppendingString:[NSString stringWithFormat:@"%@\n", log]]];
    
}

- (IBAction)onDebugButtonTapped:(id)sender
{
    [self onExitRegion];
}

#pragma mark - Estimote

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
    
    [_delayedNotificationTimer invalidate];
    [_delayedSoundTimer invalidate];
    [_repeatSoundTimer invalidate];
    
    [_paymentAlertView dismissWithClickedButtonIndex:0 animated:YES];
    
    [self endBackgroundTask];
}

@end
