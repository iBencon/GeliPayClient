//
//  GPCViewController.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface GPCViewController ()
@property NSTimer *startCountDownTimer;
@property NSTimer *playSoundTimer;
@property UIBackgroundTaskIdentifier bgTask;
@end

@implementation GPCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIApplication* app = [UIApplication sharedApplication];
    
    NSLog(@">>>>> Start Background Task.");
    _bgTask = [app beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@">>>>> End Background Task.");
        [app endBackgroundTask:_bgTask];
        _bgTask = UIBackgroundTaskInvalid;
    }];
    
    _startCountDownTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                            target:self
                                                          selector:@selector(startCountDown)
                                                          userInfo:nil
                                                           repeats:NO];
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)startCountDown
{
    NSLog(@">>>>> Notify and Start Count Down.");
    _playSoundTimer = [NSTimer scheduledTimerWithTimeInterval:3
                                                       target:self
                                                     selector:@selector(playSound)
                                                     userInfo:nil repeats:NO];
}

- (void)playSound
{
    NSLog(@">>>>> Play Sound");
    AudioServicesPlaySystemSound(1000);
}

- (void)payment
{
    NSLog(@">>>>> Payment");
    
}

@end
