//
//  TMAppDelegate.m
//  jiankongbao
//
//  Created by Tomasen on 2/19/14.
//  Copyright (c) 2014 Tomasen. All rights reserved.
//

#import "TMAppDelegate.h"
#import "TMJKB.h"
#import "GAI.h"
#import "Config.h"

@implementation TMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override point for customization after application launch.
#ifdef GATRACKERID
  [[GAI sharedInstance] trackerWithTrackingId:GATRACKERID];
#endif

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
	if (_modalSummaryViewController != nil && [_modalSummaryViewController respondsToSelector:@selector(refreshTaskList:)])
	{
		[_modalSummaryViewController refreshTaskList:self];
	}
	
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
  NSLog(@"performFetchWithCompletionHandler");
  
  NSDictionary* lastFaultyTasks = [NSDictionary dictionaryWithDictionary:[TMJKB _instance].faultyTasks];
  [[TMJKB _instance] fetchTaskList:nil completeHandler:^(NSInteger statusCode)
   {
     BOOL hasNewData = NO;
     switch (statusCode) {
       case 200:
         for (NSString* key in [TMJKB _instance].faultyTasks)
         {
           if ([lastFaultyTasks objectForKey:key] == nil)
           {
             hasNewData = YES;
             [self presentNotification:[[TMJKB _instance].faultyTasks objectForKey:key] error:YES];
           }
         }
				 
         for (NSString* key in lastFaultyTasks)
         {
           if ([[TMJKB _instance].faultyTasks objectForKey:key] == nil)
           {
             hasNewData = YES;
             [self presentNotification:[lastFaultyTasks objectForKey:key] error:NO];
           }
         }
				 
         completionHandler(hasNewData?UIBackgroundFetchResultNewData:UIBackgroundFetchResultNoData);
         break;
       case -1:
         [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
         break;
       default:
         completionHandler(UIBackgroundFetchResultFailed);
         break;
     }
     
   }];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
  NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken");
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
  NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
}

-(void)presentNotification:(NSDictionary*)task error:(BOOL)faulty
{
  UILocalNotification *localNotif = [[UILocalNotification alloc] init];
  
  localNotif.alertBody = [NSString stringWithFormat:@"监控项目 [%@] %@%@",
                          [task objectForKey:@"task_name"],
                          faulty?@"发生故障":@"刚刚恢复正常",
                          faulty?[NSString stringWithFormat:@": %@", [task objectForKey:@"last_resp_status"]]:@""];
  localNotif.timeZone = [NSTimeZone defaultTimeZone];
  localNotif.soundName = UILocalNotificationDefaultSoundName;
  
  [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
}

@end
