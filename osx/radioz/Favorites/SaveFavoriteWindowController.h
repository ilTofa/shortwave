//
//  SaveFavoriteWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 03/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>
#import <ParseOSX/Parse.h>

@class SaveFavoriteWindowController;

@protocol SaveFavoriteWindowControllerDelegate <NSObject>
- (void)saveFavoriteWindowControllerDidSelect:(SaveFavoriteWindowController *)controller;
@end

@interface SaveFavoriteWindowController : NSWindowController

@property (weak) IBOutlet NSTextField *radioNameLabel;
@property (weak) IBOutlet NSTextField *urlLabel;
@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSTextField *radioUrlLabel;
@property (weak) IBOutlet NSTextField *radioCityLabel;
@property (weak) IBOutlet NSTextField *countryLabel;
@property (weak) IBOutlet NSTextField *radioNameInput;
@property (weak) IBOutlet NSTextField *urlInput;
@property (weak) IBOutlet NSTextField *infoInput;
@property (weak) IBOutlet NSTextField *radioUrlInput;
@property (weak) IBOutlet NSTextField *radioCityInput;
@property (weak) IBOutlet NSTextField *countryInput;

@property (strong, nonatomic) NSMutableDictionary *theRadio;
@property (assign, nonatomic) id<SaveFavoriteWindowControllerDelegate> delegate;

- (IBAction)cancelIt:(id)sender;
- (IBAction)saveIt:(id)sender;

-(void)configureDefaultRadio;

@end
