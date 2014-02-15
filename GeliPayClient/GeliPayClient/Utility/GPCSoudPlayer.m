//
//  GPCSoudPlayer.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCSoudPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface GPCSoudPlayer ()

@property NSTimer *repeatSoundTimer;

@end

@implementation GPCSoudPlayer

+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static GPCSoudPlayer *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[GPCSoudPlayer alloc] init];
    });
    return sharedInstance;
}

static const CGFloat kSoundRepetInterval = 3.0f;
- (void)startRepeat
{
    [self playSound];
    _repeatSoundTimer = [NSTimer scheduledTimerWithTimeInterval:kSoundRepetInterval
                                                         target:self
                                                       selector:@selector(playSound)
                                                       userInfo:nil
                                                        repeats:YES];
}

- (void)stop
{
    [_repeatSoundTimer invalidate];
}

#pragma mark - Private

- (void)playSound
{
    AVSpeechSynthesizer* speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    NSString* speakingText = @"私のトイレは長いです。";
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:speakingText];
    [utterance setRate:0.3];
    [speechSynthesizer speakUtterance:utterance];
}

@end
