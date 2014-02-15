//
//  GPCDeviceInformation.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/15.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCDeviceInformation.h"
#import <AdSupport/AdSupport.h>

@implementation GPCDeviceInformation

+ (NSString *)uniqueID
{
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
}

@end
