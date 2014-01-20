//
//  RadiozAppDelegate.h
//  radioz
//
//  Created by Giacomo Tufano on 20/11/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

#import "iRate.h"
#import "PiwikTracker.h"

@class CoreDataController;

// global notifications
#define kMainUIBusy     @"Action Pending On Main UI"
#define kMainUIReady    @"Main UI pending"

@interface RadiozAppDelegate : NSObject <NSApplicationDelegate, iRateDelegate>

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, strong, readonly) CoreDataController *coreDataController;

@property (nonatomic, strong) PiwikTracker *tracker;

- (IBAction)saveAction:(id)sender;

@end
