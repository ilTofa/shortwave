//
//  radioListWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 03/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

#import "Radio.h"

@class RadioListWindowController;

@protocol RadioListWindowControllerDelegate <NSObject>
- (void)radioListWindowControllerDidSelect:(RadioListWindowController *)controller withObject:(Radio *)radio;
@end

@interface RadioListWindowController : NSWindowController

@property (assign, nonatomic) id<RadioListWindowControllerDelegate> delegate;

@property (weak, atomic) IBOutlet NSManagedObjectContext *sharedManagedObjectContext;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSTableView *theTable;

@property (strong, nonatomic) NSString *theSelectedStreamURL;

@property (weak) IBOutlet NSButton *playButton;

- (IBAction)radioSelected:(id)sender;
- (IBAction)search:(id)sender;

@end
