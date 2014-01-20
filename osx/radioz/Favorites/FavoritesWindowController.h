//
//  FavoritesWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 28/11/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

#import <ParseOSX/Parse.h>

@class FavoritesWindowController;

@protocol FavoritesWindowControllerDelegate <NSObject>

- (void)favoritesWindowControllerDidSelect:(FavoritesWindowController *)controller withObject:(PFObject *)favorite;

@end

@interface FavoritesWindowController : NSWindowController

@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet NSTableView *theTable;
@property (weak) IBOutlet NSButton *playButton;

@property (assign) id<FavoritesWindowControllerDelegate> delegate;

- (IBAction)selectPressed:(id)sender;
- (IBAction)deletePressed:(id)sender;

@end
