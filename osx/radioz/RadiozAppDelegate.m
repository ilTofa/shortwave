//
//  RadiozAppDelegate.m
//  radioz
//
//  Created by Giacomo Tufano on 20/11/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadiozAppDelegate.h"
#import <ParseOSX/Parse.h>
#import "CoreDataController.h"
#import "SDCloudUserDefaults.h"
#import "NSString+UUID.h"
#import "iRate.h"
#import "keys.h"

@implementation RadiozAppDelegate

+ (void)initialize {
    // Init iRate
    [iRate sharedInstance].daysUntilPrompt = 5;
    [iRate sharedInstance].usesUntilPrompt = 15;
    [iRate sharedInstance].onlyPromptIfMainWindowIsAvailable = NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Init Parse, PiwikTracker and iRate
    [Parse setApplicationId:PARSE_APPID clientKey:PARSE_KEY];
    [PFUser enableAutomaticUser];
    PFACL *defaultACL = [PFACL ACL];
    // If you would like all objects to be private by default, remove this line.
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    self.tracker = [PiwikTracker sharedInstanceWithBaseURL:[NSURL URLWithString:PIWIK_URL] siteID:SITE_ID authenticationToken:PIWIK_TOKEN];
    [iRate sharedInstance].delegate = self;
    
    // Init core data
    _coreDataController = [[CoreDataController alloc] init];
    [_coreDataController loadPersistentStores];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [self.coreDataController.mainThreadContext undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![self.coreDataController.mainThreadContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![self.coreDataController.mainThreadContext save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.

    if (!self.coreDataController.mainThreadContext) {
        return NSTerminateNow;
    }
    
    if (![self.coreDataController.mainThreadContext commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![self.coreDataController.mainThreadContext hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![self.coreDataController.mainThreadContext save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

#pragma mark - iRateDelegate

- (void)iRateUserDidAttemptToRateApp {
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"rate" action:@"iRateUserDidAttemptToRateApp" label:@""];
}

- (void)iRateUserDidDeclineToRateApp {
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"rate" action:@"iRateUserDidDeclineToRateApp" label:@""];
}

- (void)iRateUserDidRequestReminderToRateApp {
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"rate" action:@"iRateUserDidRequestReminderToRateApp" label:@""];
}

@end
