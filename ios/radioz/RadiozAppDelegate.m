//
//  RadiozAppDelegate.m
//  radioz
//
//  Created by Giacomo Tufano on 12/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadiozAppDelegate.h"
#import <Parse/Parse.h>
#import "SDCloudUserDefaults.h"
#import "NSString+UUID.h"
#import "CoreDataController.h"
#import "PiwikTracker.h"
#import "iRate.h"
#import "keys.h"

@interface RadiozAppDelegate ()

@end

@implementation RadiozAppDelegate

+ (void)initialize {
    // Init iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 10;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:PARSE_APPID clientKey:PARSE_KEY];

    // Init core data
    _coreDataController = [[CoreDataController alloc] init];
    [_coreDataController loadPersistentStores];

    // Init piwiktracker library
    self.tracker = [PiwikTracker sharedInstanceWithBaseURL:[NSURL URLWithString:PIWIK_URL] siteID:SITE_ID authenticationToken:PIWIK_TOKEN];
    
    // Set window background for curl color
    self.window.backgroundColor = [UIColor colorWithRed:105.0/256.0 green:84.0/256.0 blue:62.0/256.0 alpha:1.0];

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
    [SDCloudUserDefaults removeNotifications];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [SDCloudUserDefaults registerForNotifications];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [SDCloudUserDefaults removeNotifications];
}

- (IBAction)play:(id)sender {
}
@end
