//
//  SongListWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 05/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>

@interface SongListWindowController : NSWindowController

@property (weak, atomic) IBOutlet NSManagedObjectContext *sharedManagedObjectContext;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (weak) IBOutlet NSTableView *theTable;

@property (strong, nonatomic) NSString *theSelectedTitle;
@property (strong, nonatomic) NSString *theSelectedArtist;
@property (strong, nonatomic) NSData *theSelectedCover;
@property (strong, nonatomic) NSURL *iTunesURL;

- (IBAction)gotoStore:(id)sender;
- (IBAction)deleteSong:(id)sender;

@end
