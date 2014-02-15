//
//  GPCLocalNotificationHelper.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/16.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

#import "GPCLocalNotificationHelper.h"

@implementation GPCLocalNotificationHelper

+ (void)simpleLocalNotificationWithBody:(NSString *)body
{
    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
    [localNotification setAlertBody:body];
    [localNotification setSoundName:UILocalNotificationDefaultSoundName];
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];

}

@end
