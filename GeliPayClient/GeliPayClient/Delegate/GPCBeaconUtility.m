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
@property ESTBeaconRegion   *region;
@end

const NSInteger kBeaconMajorID = 6521;
const NSInteger kBeaconMinorID = 13509;

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
    _region = [[ESTBeaconRegion alloc] initWithProximityUUID:ESTIMOTE_PROXIMITY_UUID
                                                       major:kBeaconMajorID
                                                       minor:kBeaconMinorID
                                                  identifier:@"jp.co.GeliPayClient.iBencon"];

    [_beaconManager startRangingBeaconsInRegion:_region];

    [_beaconManager startMonitoringForRegion:_region];
    [self requestStatusForRegion];
}

- (void)requestStatusForRegion
{
    [_beaconManager requestStateForRegion:_region];
}

- (void)forceLogout
{
    _isEnter = YES;
    [self onExitRegion];
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self requestStatusForRegion];

    });}

- (void)beaconManager:(ESTBeaconManager *)manager
      didRangeBeacons:(NSArray *)beacons
             inRegion:(ESTBeaconRegion *)region
{
    if([beacons count] > 0) {
        ESTBeacon *selectedBeacon = beacons[0];
        
        switch (selectedBeacon.proximity)
        {
            case CLProximityNear:
            [self onEnterRegion:region];
            break;
            case CLProximityImmediate:
            [self onEnterRegion:region];
            break;
            default:
            [self onExitRegion];
            break;
        }
    }
}

- (void)beaconManager:(ESTBeaconManager *)manager
    didDetermineState:(CLRegionState)state
            forRegion:(ESTBeaconRegion *)region
{
    if (state == CLRegionStateInside) {
        [self onEnterRegion:region];
    } else {
        [self onExitRegion];
    }
}

- (void)onEnterRegion:(ESTBeaconRegion *)region
{
    if (_isEnter) return;
    _isEnter = YES;
 
    [[GPCBackgroundTaskManager sharedInstance] startBackgroundTask];
    
    [_delegate onEnterRegion:region];
}

- (void)onExitRegion
{
    if (!_isEnter) return;
    _isEnter = NO;

    [_delegate onExitRegion];

    [[GPCBackgroundTaskManager sharedInstance] endBackgroundTask];
}

@end
