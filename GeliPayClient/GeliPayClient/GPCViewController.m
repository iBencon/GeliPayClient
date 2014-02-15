//
//  GPCViewController.m
//  GeliPayClient
//
//  Created by 西山 勇世 on 2014/02/14.
//  Copyright (c) 2014年 iBencon. All rights reserved.
//

//#define OFFLINE = 1
#define ONLY_FOREGROUND = 1

#import "GPCViewController.h"
#import "AFNetworking.h"
#import "GPCSoudPlayer.h"
#import "GPCBeaconUtility.h"
#import "GPCPaymentManager.h"
#import "GPCBackgroundTaskManager.h"
#import "GPCDeviceInformation.h"
#import "PayPalMobile.h"
#import "GPCCountDownTimer.h"
#import "GPCLocalNotificationHelper.h"

typedef NS_ENUM(NSInteger, ToiletStatus)
{
    ToiletStatusLogout,
    ToiletStatusLogin,
    ToiletStatusTooLong,
    ToiletStatusPaid
};

@interface GPCViewController () <GPCBeaconUtilityDelegate, GPCPaymentManagerDelegate, GPCCountDownTimerDelegate>

@property NSTimer                   *delayedNotificationTimer;
@property UIAlertView               *paymentAlertView;

@property (strong, nonatomic) IBOutlet UILabel *logoLabel;
@property (strong, nonatomic) IBOutlet UIImageView  *statusImage;
@property (strong, nonatomic) IBOutlet UILabel      *informationLabel;
@property (strong, nonatomic) IBOutlet UIButton     *paymentButton;
@property (strong, nonatomic) IBOutlet UITextView   *debugLogView;

@end

@implementation GPCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[GPCBeaconUtility sharedInstance] setDelegate:self];
    [[GPCPaymentManager sharedInstance] setDelegate:self];
    [self updateUI:ToiletStatusLogout];
    [_statusImage setContentMode:UIViewContentModeScaleAspectFit];
    [self lotationLogo3D];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)willEnterForeground
{
    [self lotationLogo3D];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [PayPalPaymentViewController setEnvironment:PayPalEnvironmentNoNetwork];
    [PayPalPaymentViewController prepareForPaymentUsingClientId:kPayPalClientID];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)lotationLogo3D
{
    CABasicAnimation* animation = [CABasicAnimation
                                   animationWithKeyPath:@"transform.rotation.x"];
    animation.fromValue = @(0);
    animation.toValue = @(2 * M_PI);
    animation.repeatCount = INFINITY;
    animation.duration = 15.0;
    
    [self.logoLabel.layer addAnimation:animation forKey:@"rotation"];
    
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / 500.0;
    self.logoLabel.layer.transform = transform;
}

static const CGFloat kPlaySoundDelayTime = 5.0f;
- (void)notifyAndPlaySoundAfterDelay
{
    [[GPCCountDownTimer sharedInstance] executeBlock:^{
        [[GPCSoudPlayer sharedInstance] startRepeat];
        [self updateUI:ToiletStatusTooLong];
    }
                                          afterDelay:kPlaySoundDelayTime
                                        delegate:self];
    [[GPCPaymentManager sharedInstance] presentPaymentLocalNotification];
}

- (IBAction)onPaymentTapped:(id)sender {
    [self presentPaymentViewController];
}

- (void)updateUI:(ToiletStatus)status
{

    switch (status) {
        case ToiletStatusLogout:
            [_statusImage setImage:[UIImage imageNamed:@"logout"]];
            [_paymentButton setHidden:YES];
            [_informationLabel setText:@"ログアウト中"];
            break;
        case ToiletStatusLogin:
            [_statusImage setImage:[UIImage imageNamed:@"login"]];
            [_paymentButton setHidden:YES];
            [_informationLabel setText:@"ログイン中"];
            break;
        case ToiletStatusTooLong:
            [_statusImage setImage:[UIImage imageNamed:@"login"]];
            [_paymentButton setHidden:NO];
            [_informationLabel setText:@"長居しています"];
            break;
        case ToiletStatusPaid:
            [_statusImage setImage:[UIImage imageNamed:@"login"]];
            [_paymentButton setHidden:YES];
            [_informationLabel setText:@"ごゆっくり"];
            break;
    }
}

#pragma mark -Debug

- (void)showLog:(NSString *)log
{
    //[_debugLogView setText:[[_debugLogView text] stringByAppendingString:[NSString stringWithFormat:@"%@\n", log]]];
    [_debugLogView setText:[NSString stringWithFormat:@"%@", log]];

}

- (IBAction)onDebugButtonTapped:(id)sender
{
    [[GPCBackgroundTaskManager sharedInstance] startBackgroundTask];
    [self onExitRegion];
}

#pragma mark - Countdown Timer Delegate

- (void)onUpdateTime:(NSTimeInterval)restTime
{
    NSInteger integerTime = (NSInteger)roundf(restTime);
    [_informationLabel setText:[NSString stringWithFormat:@"残り %d秒",integerTime]];
}

#pragma mark - Estimote Delegate

static const CGFloat kNotifyAndStartCountDownTime = 5.0f;
- (void)onEnterRegion:(ESTBeaconRegion *)region
{
    [self showLog:@">>>>> onEnterRegion"];
    
    [GPCLocalNotificationHelper simpleLocalNotificationWithBody:@"トイレにログインしました"];
    
    [self updateUI:ToiletStatusLogin];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"devise_id" : [NSString stringWithFormat:@"%@-%@", [region major], [region minor]],
                            @"uid" : [GPCDeviceInformation uniqueID]};
    [manager POST:@"http://gelipay.herokuapp.com/users.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"response: %@", responseObject);
        if ([responseObject count] == 1) {
            [self showLog:@">>>>> API Error (users)"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self showLog:@">>>>> API Error (users)"];
    }];
#endif
    
    _delayedNotificationTimer = [NSTimer scheduledTimerWithTimeInterval:kNotifyAndStartCountDownTime
                                                                 target:self
                                                               selector:@selector(notifyAndPlaySoundAfterDelay)
                                                               userInfo:nil
                                                                repeats:NO];
}

- (void)onExitRegion
{
    [self showLog:@">>>>> onExitRegion"];
    
    [GPCLocalNotificationHelper simpleLocalNotificationWithBody:@"トイレからログアウトしました"];
    
    [self updateUI:ToiletStatusLogout];

#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"uid" : [GPCDeviceInformation uniqueID]};
    [manager DELETE:@"http://gelipay.herokuapp.com/users/exit.json"
         parameters:param
            success:^(AFHTTPRequestOperation *operation, id responseObject)
            {
                NSLog(@">>>>> Response: %@", responseObject);
            }
            failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@">>>>> Error: %@", error);
                [self showLog:@">>>>> API Error (users/exit)"];
    }];
#endif
    [[GPCCountDownTimer sharedInstance] cancel];
    [_delayedNotificationTimer invalidate];
    [[GPCPaymentManager sharedInstance] dismissPaymentAlert];
    [[GPCSoudPlayer sharedInstance] stop];
}

#pragma mark - Payment Delegate

-(void)presentPaymentViewController
{
    PayPalPayment *payment = [[PayPalPayment alloc] init];
    payment.amount = [[NSDecimalNumber alloc] initWithString:@"39.95"];
    payment.currencyCode = @"USD";
    payment.shortDescription = @"下痢止め";
    
    if (!payment.processable) {
        NSLog(@"This payment would not be processable.");
    }
    
    [PayPalPaymentViewController setEnvironment:PayPalEnvironmentNoNetwork];
    
    NSString *aPayerId = @"allegllet.scherzand.paypal@gmail.com";
    
    PayPalPaymentViewController *paymentViewController;
    paymentViewController = [[PayPalPaymentViewController alloc] initWithClientId:kPayPalClientID
                                                                    receiverEmail:kReceiverEmail
                                                                          payerId:aPayerId
                                                                          payment:payment
                                                                         delegate:[GPCPaymentManager sharedInstance]];
    
    [self presentViewController:paymentViewController animated:YES completion:nil];
}

- (void)didPaid
{
    [self showLog:@">>>>> Paid"];
    
#ifndef OFFLINE
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    NSDictionary* param = @{@"devise_id" : [NSString stringWithFormat:@"%ld-%d", (long)kBeaconMajorID, kBeaconMinorID],
                            @"uid" : [GPCDeviceInformation uniqueID]};
    [manager POST:@"http://gelipay.herokuapp.com/users/pay.json" parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@">>>>> Response: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@">>>>> Error: %@", error);
        [self showLog:@">>>>> API Error (users/pay)"];
    }];
#endif
    [[GPCCountDownTimer sharedInstance] cancel];
    [[GPCSoudPlayer sharedInstance] stop];
    [self dismissViewControllerAnimated:YES completion:^{
        [self updateUI:ToiletStatusPaid];
    }];
}

- (void)didCancel
{
    [self dismissViewControllerAnimated:YES completion:^{
        [self updateUI:ToiletStatusTooLong];
    }];
}


@end
