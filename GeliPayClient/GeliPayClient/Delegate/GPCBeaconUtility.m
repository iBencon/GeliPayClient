//
//  GPCBeaconManagerDelegate.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCBeaconUtility.h"
#import <ESTBeaconManager.h>
#import "AFNetworking.h"
#import "GPCDeviceInformation.h"
#import "GPCBackgroundTaskManager.h"

@interface GPCBeaconUtility () <ESTBeaconManagerDelegate>
@property ESTBeaconManager  *beaconManager;
@property BOOL              isEnter;
@end

static const NSInteger kBeaconMajorId = 6521;
static const NSInteger kBeaconMinorId = 13509;

@implementation GPCBeaconUtility

+ (id)sharedInstance
{
    static dispatch_once_t pred;
    static GPCBeaconUtility *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[GPCBeaconUtility alloc] init];
        [sharedInstance setupBeacon];
    });
    return sharedInstance;
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

- (void)onEnterRegion
{
    if (_isEnter) return;
    _isEnter = YES;
 
    [[GPCBackgroundTaskManager sharedInstance] startBackgroundTask];
    
    [_delegate onEnterRegion];
}

- (void)onExitRegion
{
    if (!_isEnter) return;
    _isEnter = NO;

    [_delegate onExitRegion];

    [[GPCBackgroundTaskManager sharedInstance] endBackgroundTask];
}

@end
