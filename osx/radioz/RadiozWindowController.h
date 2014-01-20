//
//  RadiozWindowController.h
//  radioz
//
//  Created by Giacomo Tufano on 27/11/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Cocoa/Cocoa.h>
#import "AudioStreamer.h"
#import "Bunny.h"

@interface RadiozWindowController : NSWindowController
{
    dispatch_queue_t theBunnyQueue;
}

// This is the audio streamer
@property (strong, nonatomic) AudioStreamer *theStreamer;

// this is the currently selected radio.
@property (strong, nonatomic) NSMutableDictionary *theSelectedRadio;
// The URL to the actual stream and to the redirector for the current radio
@property (copy, nonatomic) NSString *currentRadioURL;
@property (copy, nonatomic) NSString *currentRadioRedirectorURL;
// The queue for background image loading
@property (strong, nonatomic) NSOperationQueue *imageLoadQueue;

// The window background image
@property (weak) IBOutlet NSImageView *backgroundImage;
// The text on UI
@property (weak) IBOutlet NSTextField *stationInfo;
@property (weak) IBOutlet NSTextField *genreInfo;
@property (weak) IBOutlet NSTextField *locationInfo;
@property (weak) IBOutlet NSTextField *radioURL;
@property (weak) IBOutlet NSTextField *metadataInfo;
// The play/stop button and menu
@property (weak) IBOutlet NSButton *playOrStopButton;
@property (weak) IBOutlet NSMenuItem *playOrStopMenu;
// The Dock menu items
@property (weak) IBOutlet NSMenuItem *playOrStopDockMenu;
@property (weak) IBOutlet NSMenuItem *radioNameDockMenu;
@property (weak) IBOutlet NSMenuItem *songTitleDockMenu;
// The status menu items
@property (strong) NSStatusItem *theStatusItem;
@property (strong) IBOutlet NSMenu *theStatusMenu;
@property (weak) IBOutlet NSMenuItem *playOrStopStatusMenu;
@property (weak) IBOutlet NSMenuItem *radioNameStatusMenu;
@property (weak) IBOutlet NSMenuItem *songTitleStatusMenu;
@property (weak) IBOutlet NSMenuItem *aboutMenu;
// The spinner for "busy connecting" indicator
@property (weak) IBOutlet NSProgressIndicator *spinner;
// The timeout timer for killing the connection after a while..
@property (strong, nonatomic) NSTimer *timeoutTimer;
// UI buttons
@property (weak) IBOutlet NSButton *lyricsButton;
@property (weak) IBOutlet NSButton *webButton;
@property (weak) IBOutlet NSButton *saveFavorites;
@property (weak) IBOutlet NSButton *addSongButton;
@property (weak) IBOutlet NSButton *songListButton;
@property (weak) IBOutlet NSButton *favoritesListButton;
@property (weak) IBOutlet NSButton *radioListButton;
@property (weak) IBOutlet NSButton *bunniesButton;
@property (weak) IBOutlet NSButton *aboutButton;

// Metadate temporary handlers
@property (copy, nonatomic) NSString *currentSongName;
@property (strong) NSImage *coverImage;
@property (nonatomic) BOOL isCoverArtAlreadyLoaded;
// The selected bunny
@property (strong, nonatomic) Bunny *theSelectedBunny;

// Actions
- (IBAction)playOrStop:(id)sender;
- (IBAction)bunnyClocked:(id)sender;
- (IBAction)getFavorites:(id)sender;
- (IBAction)loadLyrics:(id)sender;
- (IBAction)loadRadioWeb:(id)sender;
- (IBAction)saveFavorite:(id)sender;
- (IBAction)getRadios:(id)sender;
- (IBAction)loadSongList:(id)sender;
- (IBAction)addSong:(id)sender;
- (IBAction)nukeDB:(id)sender;
- (IBAction)openPreferences:(id)sender;

@end
