//
//  SaveBunnyWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 05/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

@class SaveBunnyWindowController;

@protocol SaveBunnyWindowControllerDelegate <NSObject>

- (void)saveBunnyWindowControllerDidSave:(SaveBunnyWindowController *)controller;

@end

@interface SaveBunnyWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *nameLabel;
@property (weak) IBOutlet NSTextField *apiLabel;
@property (weak) IBOutlet NSTextField *name;
@property (weak) IBOutlet NSTextField *key;
@property (weak) IBOutlet NSSegmentedControl *bunnyType;


@property (assign, nonatomic) id<SaveBunnyWindowControllerDelegate> delegate;

- (IBAction)save:(id)sender;

@end
