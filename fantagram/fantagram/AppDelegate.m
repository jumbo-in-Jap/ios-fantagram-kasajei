//
//  AppDelegate.m
//  fantagram
//
//  Created by Kasajima Yasuo on 2013/01/02.
//  Copyright (c) 2013年 kasajei. All rights reserved.
//

#import "AppDelegate.h"
#import "Appirater.h"
#import "GAI.h"
#import <Parse/Parse.h>
#import "UIKitHelper.h"
#import "Parameter.h"



@interface AppDelegate (){
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // Appirater
    [Appirater setAppId:APP_ID];
    [Appirater setDaysUntilPrompt:2];
    [Appirater setUsesUntilPrompt:20];
    [Appirater setSignificantEventsUntilPrompt:-1];
    [Appirater setTimeBeforeReminding:2];
    [Appirater appLaunched:YES];
    
    // GoogleAnalytic
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 20;
    // Optional: set debug to YES for extra debugging information.
    [GAI sharedInstance].debug = YES;
    // Create tracker instance.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:UA_TRACKING_ID];
    
    
    // Parse
    [Parse setApplicationId:PARSE_APPLICATION_ID
                  clientKey:PARSE_CLIENT_KEY];
    
    [PFUser enableAutomaticUser];
    
    PFACL *defaultACL = [PFACL ACL];
    
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
    // Pushの登録
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
     UIRemoteNotificationTypeAlert|
     UIRemoteNotificationTypeSound];
    
    [self setUserChannel];
    
    // アプリが起動されていなくて、Pushで開いた場合はここに情報がはいる。バックグランドやアプリを開いているときはdidRecieveの方が呼ばれる
    NSDictionary *notifPayload =
    [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    LOG(@"%@", notifPayload);
    [self pushShowAlert:notifPayload];
    
    UINavigationController *vc = (UINavigationController *)self.window.rootViewController;
    LOG(@"%@",NSStringFromClass([vc class]));
    
    
    LOG(@"%@",[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]);

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // badgeを0にしておく
//    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
//    if (currentInstallation.badge != 0) {
//        currentInstallation.badge = 0;
//        [currentInstallation saveEventually];
//    }
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setUserChannel
{
    PFUser *user = [PFUser currentUser];
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // UserIDを登録しておく
        NSString *channelStr = [NSString stringWithFormat:@"user_%@",[PFUser currentUser].objectId];
        [PFPush subscribeToChannelInBackground:channelStr];
        
        // 設定言語を登録しておく
        NSArray *languages = [NSLocale preferredLanguages];
        NSString *lang = [languages objectAtIndex:0];
        [PFPush subscribeToChannelInBackground:lang];
        
        // ToMoreAppView
        [PFPush subscribeToChannelInBackground:@"ToMoreAppView"];
    }];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    LOG(@"test");
    [PFPush storeDeviceToken:newDeviceToken];
    // Subscribe this user to the broadcast channel, ""
    [PFPush subscribeToChannelInBackground:@"" block:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            LOG(@"Successfully subscribed to the broadcast channel.");
            [self setUserChannel];
        } else {
            // エラー処理
            LOG(@"Failed to subscribe to the broadcast channel.");
        }
    }];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        LOG(@"Push notifications are not supported in the iOS Simulator.");
    } else {
        // show some alert or otherwise handle the failure to register.
        LOG(@"application:didFailToRegisterForRemoteNotificationsWithError: %@", error);
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [self pushShowAlert:userInfo];
}


- (void)subscribeFinished:(NSNumber *)result error:(NSError *)error {
    if ([result boolValue]) {
        LOG(@"ParseStarterProject successfully subscribed to push notifications on the broadcast channel.");
    } else {
        LOG(@"ParseStarterProject failed to subscribe to push notifications on the broadcast channel.");
    }
}


#pragma mark PushAction
- (void)pushShowAlert:(NSDictionary *)userInfo{
    if (userInfo == NULL)
        return;
    
    switch ([userInfo integerForKey:@"action"]) {
        case 1: // OKボタンだけで、アクションあり
            [self showOKAlertView:userInfo withAction:true];
            break;
        case 2: // OKボタンとキャンセルで、OKのときはアクション
            [self showOKOrCancelView:userInfo];
            break;
        case 3:
            [self showUpdateAlertView:userInfo];
            break;
        default: // OKボタンだけで、アクションない
            [self showOKAlertView:userInfo withAction:false];
            break;
    }
}

- (void)showOKAlertView:(NSDictionary *)userInfo withAction:(BOOL)isAction{
    NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message];
    __weak id blockSelf = self;
    [alertView addButtonWithTitle:@"OK" handler:^(){
        if (isAction)
            [blockSelf pushAction:userInfo];
    }];
    [alertView show];
}

- (void)showOKOrCancelView:(NSDictionary *)userInfo{
    NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message];
    [alertView addButtonWithTitle:@"Cancel" handler:^(){
        
    }];
    
    __weak id blockSelf = self;
    [alertView addButtonWithTitle:@"OK" handler:^(){
        [blockSelf pushAction:userInfo];
    }];
    
    [alertView show];

}

- (void)showUpdateAlertView:(NSDictionary *)userInfo{
    NSString *appversion = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"];
    NSString *newVersion = [userInfo objectForKey:@"newVersion"];
    if (![appversion isEqualToString:newVersion]) {
        NSString *message = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" message:message];
        [alertView addButtonWithTitle:@"Cancel" handler:^(){
            
        }];
        
        [alertView addButtonWithTitle:@"OK" handler:^(){
            NSURL *url = [NSURL URLWithString:APP_URL];
            [[UIApplication sharedApplication] openURL:url];
        }];
        
        [alertView show];
    }
}

-(void)pushAction:(NSDictionary *)userInfo{
    UINavigationController *vc = (UINavigationController *)self.window.rootViewController;
    LOG(@"%@", NSStringFromClass([vc class]));
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UIViewController * visibleViewController = vc.visibleViewController;
        LOG(@"%@", NSStringFromClass([visibleViewController class]));
        if ([visibleViewController respondsToSelector:@selector(pushAction:)]) {
            [visibleViewController performSelector:@selector(pushAction:) withObject:userInfo];
        }
    }
    LOG(@"%@",userInfo);
}



@end
