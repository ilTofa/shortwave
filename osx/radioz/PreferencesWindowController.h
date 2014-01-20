//
//  PreferencesWindowController.h
//  radiox
//
//  Created by Giacomo Tufano on 07/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

@class PreferencesWindowController;

@protocol PreferencesWindowControllerDelegate <NSObject>
- (void)preferencesWindowControllerDidSelect:(PreferencesWindowController *)controller;
@end

@interface PreferencesWindowController : NSWindowController

@property (weak) IBOutlet NSButton *sysMenuButton;
@property (assign, nonatomic) id<PreferencesWindowControllerDelegate> delegate;

- (IBAction)useSystemMenu:(id)sender;

@end
