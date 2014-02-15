//
//  GPCBeaconManagerDelegate.h
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GPCBeaconUtilityDelegate <NSObject>
- (void)onEnterRegion;
- (void)onExitRegion;
@end

@interface GPCBeaconUtility : NSObject

@property (weak) id <GPCBeaconUtilityDelegate>  delegate;

+ (id)sharedInstance;

@end
