//
//  AppDelegate.m
//  ShufflePlayer
//
//  Created by Keiichiro Watanabe on 2013/10/17.
//  Copyright (c) 2013年 ahomegane. All rights reserved.
//

#import "AppDelegate.h"
#import "SCUI.h"
#import "Constants.h"

@implementation AppDelegate

@synthesize viewController;

+ (void)initialize {
  [SCSoundCloud setClientID:SC_CLIENT_ID
                     secret:SC_CLIENT_SECRET
                redirectURL:[NSURL URLWithString:SC_API_REDIRECT_URL]];
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  
  NSLog(@"didFinishLaunchingWithOptions");
  
  // 自動ロック／スリープの禁止
  [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
  
  NSDictionary *userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];

  if (userInfo != nil) {
    if ([[userInfo objectForKey:@"id"] isEqualToString:@"alarm"]) {
      self.viewController.lunchAlarmFlag = YES;
    }
  }
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Sent when the application is about to move from active to inactive state.
  // This can occur for certain types of temporary interruptions (such as an
  // incoming phone call or SMS message) or when the user quits the application
  // and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down
  // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
  // Use this method to release shared resources, save user data, invalidate
  // timers, and store enough application state information to restore your
  // application to its current state in case it is terminated later.
  // If your application supports background execution, this method is called
  // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
  // Called as part of the transition from the background to the inactive state;
  // here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  // Restart any tasks that were paused (or not yet started) while the
  // application was inactive. If the application was previously in the
  // background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
  // Called when the application is about to terminate. Save data if
  // appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
  NSDictionary * userInfo = notification.userInfo;
  UIApplicationState state = [application applicationState];
  if (userInfo != nil) {
    if ([[userInfo objectForKey:@"id"] isEqualToString:@"alarm"]) {
      if (state == UIApplicationStateInactive) NSLog(@"UIApplicationStateInactive");
      if (state == UIApplicationStateActive) NSLog(@"UIApplicationStateActive");
      if (state == UIApplicationStateInactive) {
        NSLog(@"UIApplicationStateInactive");
        [self.viewController.alarmVC overrideSelectedTime:[NSDate date]];
      }
    }
  }
}

@end
