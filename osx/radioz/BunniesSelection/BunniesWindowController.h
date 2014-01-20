//
//  BunniesWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 05/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

#import "Bunny.h"

@class BunniesWindowController;

@protocol BunniesWindowControllerDelegate <NSObject>

- (void)bunniesWindowControllerDidSelect:(BunniesWindowController *)controller withObject:(Bunny *)theBunny;

@end

@interface BunniesWindowController : NSWindowController

@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTableView *theTable;
@property (assign, nonatomic) id<BunniesWindowControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *theBunniesArray;

- (IBAction)playPressed:(id)sender;
- (IBAction)addBunny:(id)sender;
- (IBAction)deleteBunny:(id)sender;

@end
