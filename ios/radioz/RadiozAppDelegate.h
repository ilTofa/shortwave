//
//  RadiozAppDelegate.h
//  radioz
//
//  Created by Giacomo Tufano on 12/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

#import "PiwikTracker.h"

@class CoreDataController;

@interface RadiozAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, readonly) CoreDataController *coreDataController;

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) PiwikTracker *tracker;

@end
