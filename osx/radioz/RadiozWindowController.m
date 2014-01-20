//
//  RadiozWindowController.m
//  radioz
//
//  Created by Giacomo Tufano on 27/11/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadiozWindowController.h"
#import "FavoritesWindowController.h"
#import "SaveFavoriteWindowController.h"
#import "RadioListWindowController.h"
#import "BunniesWindowController.h"
#import "SongListWindowController.h"
#import "RadiozAppDelegate.h"
#import "SongAdder.h"
#import "PreferencesWindowController.h"

#import "SDCloudUserDefaults.h"
#import "Radio+ToDictionary.h"
#import "CoreDataController.h"

@interface RadiozWindowController () <FavoritesWindowControllerDelegate, SaveFavoriteWindowControllerDelegate, RadioListWindowControllerDelegate, BunniesWindowControllerDelegate, PreferencesWindowControllerDelegate>

@property FavoritesWindowController *favController;
@property SaveFavoriteWindowController *saveController;
@property RadioListWindowController *listController;
@property BunniesWindowController *bunniesController;
@property SongListWindowController *songListController;
@property PreferencesWindowController *preferencesController;

@end

@implementation RadiozWindowController

#pragma mark -
#pragma mark Helpers in iOS / OSX move

-(void)UIEnabled:(BOOL)enabled
{
    //    [self.window setAlphaValue:(enabled) ? 1.0 : 0.9];
    [self.window setIgnoresMouseEvents:!enabled];
}

#pragma mark -
#pragma mark AudioStreamer notification management

// Get cover image from iTunes store
-(void)getCoverImageFromItunesStore:(NSString *)searchString
{
    if(self.isCoverArtAlreadyLoaded)
    {
        DLog(@"coverart already loaded, no need to get it from iTunes Store");
        return;
    }
    NSString *searchUrl = [[[NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&country=us&media=music&limit=1", searchString] stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    DLog(@"Store URL is: %@", searchUrl);
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:searchUrl]];
    [req setCachePolicy:NSURLRequestUseProtocolCachePolicy];
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
     {
         DLog(@"Search from iTunes store got back %@.", (data) ? @"successfully." : @"with errors.");
         if(data)
         {
             // Get JSON data
             NSError *err;
             NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
             if(!jsonObject)
             {
                 NSLog(@"Error reading JSON data: %@", [err description]);
                 return;
             }
             else
             {
                 NSArray *songsData = jsonObject[@"results"];
                 if(songsData == nil || [songsData count] ==0)
                 {
                     NSLog(@"Error in JSON dictionary while looking for the coverart: %@", jsonObject);
                     return;
                 }
                 NSDictionary *songData = songsData[0];
                 if(!songData)
                 {
                     NSLog(@"Error in JSON first level array: %@", songsData);
                     return;
                 }
                 NSString *songURL = songData[@"artworkUrl100"];
                 if(!songURL)
                 {
                     songURL = songData[@"artworkUrl60"];
                     if(!songURL)
                     {
                         NSLog(@"Error in song dictionary: %@", songData);
                         return;
                     }
                 }
                 DLog(@"The requested song URL is: <%@>.", songURL);
                 [self.imageLoadQueue cancelAllOperations];
                 NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:songURL]];
                 [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
                  {
                      if(data)
                      {
                          self.coverImage = [[NSImage alloc] initWithData:data];
                          if(self.coverImage != nil)
                              self.isCoverArtAlreadyLoaded = YES;
                      }
                  }];
             }
         }
     }];
}

-(void)metadataNotificationReceived:(NSNotification *)note
{
    self.isCoverArtAlreadyLoaded = NO;
   // Parse metadata...
    NSString *metadata = self.theStreamer.metaDataString;
    DLog(@"Raw metadata: %@", metadata);
    DLog(@" Stream type: %@", self.theStreamer.streamContentType);
	NSArray *listItems = [metadata componentsSeparatedByString:@";"];
    NSRange range;
    for (NSString *item in listItems)
    {
        DLog(@"item: %@", item);
        // Look for title
        range = [item rangeOfString:@"StreamTitle="];
        if(range.location != NSNotFound)
        {
            NSString *temp = [[item substringFromIndex:range.length] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
            DLog(@"Song name: %@", temp);
            self.songTitleDockMenu.title = self.songTitleStatusMenu.title = temp;
            if([temp length] > 0 && [temp characterAtIndex:0] != '<')
                self.currentSongName = temp;
            NSArray *songPieces = [temp componentsSeparatedByString:@" - "];
            if([songPieces count] == 2)
            {
                NSString *tempArtist = [songPieces[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *tempTitle = [songPieces[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                // protect from malformed informations
                if(![tempArtist isEqualToString:@""] && ![tempTitle isEqualToString:@""])
                {
                    temp = [NSString stringWithFormat:@"%@\n%@", tempArtist, tempTitle];
                    // We (probably) have track titles, enable lyrics and add song buttons
                    self.lyricsButton.enabled = YES;
                    self.addSongButton.enabled = YES;
                    // if user is already reading lyrics, let's them update!
//                    if(self.theWebView.isHidden == NO)
//                        [self loadLyrics:YES];
                    // Let's try to load coverart (after a couple second to give time to the StreamUrl processing)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                        [self getCoverImageFromItunesStore:[NSString stringWithFormat:@"%@ %@", tempArtist, tempTitle]];
                    });
                }
                else
                    DLog(@"Malformed StreamTitle informations: \"%@\"", temp);
            }
            if([temp length] > 0 && [temp characterAtIndex:0] != '<')
                self.metadataInfo.stringValue = temp;
        }
        // Look for URL
        range = [item rangeOfString:@"StreamUrl="];
        if(range.location != NSNotFound)
        {
            NSString *temp = [item substringFromIndex:range.length];
            temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
            DLog(@"URL: <%@>", temp);
            [self.imageLoadQueue cancelAllOperations];
            NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:temp]];
            [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
             {
                 if(data)
                 {
                     self.coverImage = [[NSImage alloc] initWithData:data];
                     if(self.coverImage != nil)
                         self.isCoverArtAlreadyLoaded = YES;
                 }
             }];
        }
    }
}

// Bitrate and genre are in the same label
- (void)bitrateNotificationReceived:(NSNotification *)note
{
    DLog(@"bitrateUpdated");
    // Set data from stream (or use what we have on saved metadata)
    NSString *temp = @"";
    if(self.theStreamer.streamGenre)
    {
        temp = [temp stringByAppendingFormat:@"%@", self.theStreamer.streamGenre];
        // Save if new data on genre
        (self.theSelectedRadio)[@"radio_tags"] = self.theStreamer.streamGenre;
    }
    else
        temp = [temp stringByAppendingFormat:@"%@", (self.theSelectedRadio)[@"radio_tags"]];
    if(self.theStreamer.streamContentType)
        temp = [temp stringByAppendingFormat:@" on %@", self.theStreamer.streamContentType];
    if(self.theStreamer.bitRate)
        temp = [temp stringByAppendingFormat:@" @%u kbps", self.theStreamer.bitRate];
    if(![self.theStreamer.streamContentType isEqualToString:@"audio/mpeg"])
        temp = [temp stringByAppendingString:NSLocalizedString(@" (not for nabaztags)", @"")];
	self.genreInfo.stringValue = temp;
}

-(void)radioNameNotificationreceived:(NSNotification *)note
{
    DLog(@"Got the station name: \"%@\"", self.theStreamer.streamRadioName);
    self.stationInfo.stringValue = self.radioNameDockMenu.title = self.radioNameStatusMenu.title = self.theStreamer.streamRadioName;
    (self.theSelectedRadio)[@"radio_name"] = self.theStreamer.streamRadioName;
}

-(void)radioUrlNotificationreceived:(NSNotification *)note
{
    // Now get the URLs
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    NSTextCheckingResult *result = [detector firstMatchInString:self.theStreamer.streamRadioUrl options:0 range:NSMakeRange(0, [self.theStreamer.streamRadioUrl length])];
    if(result && result.range.location != NSNotFound)
    {
        DLog(@"Found radioURL: <%@>", result.URL);
        (self.theSelectedRadio)[@"radio_url"] = [result.URL absoluteString];
        self.webButton.enabled = YES;
    }
    else
    {
        NSLog(@"Not valid radioURL received: <%@>", self.theStreamer.streamRadioUrl);
    }
}

-(void)errorNotificationReceived:(NSNotification *)note
{
	NSLog(@"Stream Error.");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.spinner stopAnimation:self];
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"Attempt to play streaming audio failed.", @"")];
        [alert setMessageText:NSLocalizedString(@"Error", @"")];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [self saveRadioError:@"Attempt to play streaming audio failed."];
        [self stopPressed:nil];
    });
}

-(void)streamRedirected:(NSNotification *)note
{
	NSLog(@"Stream Redirected.");
    self.radioURL.stringValue = self.currentRadioURL = [self.theStreamer.url absoluteString];
    [self stopPressed:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [self playPressed:nil];
    });
}

-(void) startSpinner
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kMainUIBusy object:nil]];
    [self UIEnabled:NO];
    [self.spinner startAnimation:self];
}

-(void)stopSpinner:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:kMainUIReady object:nil]];
    [self UIEnabled:YES];
    [self.spinner stopAnimation:self];
    // If this is a real stream connect notification set and enable stop button (on main thread)
    if(note)
    {
        DLog(@"This is stopSpinner called from a real notification to setup interface to play.");
        dispatch_async(dispatch_get_main_queue(), ^{
            DLog(@"setting button to stop");
            if(self.timeoutTimer)
            {
                DLog(@"Killing timeout timer: %@ on %@thread", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"");
                [self.timeoutTimer invalidate];
                self.timeoutTimer = nil;
            }
            [self.playOrStopButton setImage:[NSImage imageNamed:@"button-stop"]];
            [self.playOrStopButton setAlternateImage:[NSImage imageNamed:@"button-stop-clicked"]];
            self.playOrStopMenu.title = self.playOrStopDockMenu.title = self.playOrStopStatusMenu.title = @"Stop";
            self.playOrStopButton.enabled = YES;
            // Save radio for new start (and other devices)
            [SDCloudUserDefaults setObject:self.theSelectedRadio forKey:@"selectedRadio"];
            [SDCloudUserDefaults setString:self.currentRadioURL forKey:@"currentRadioURL"];
            [SDCloudUserDefaults setString:self.currentRadioRedirectorURL forKey:@"currentRadioRedirectorURL"];
        });
    }
}

-(void)killConnectingStream:(NSTimer *)timer
{
    // stream cannot connect, kill it and reset
    dispatch_async(dispatch_get_main_queue(), ^{
        DLog(@"This is the timeout timer: %@ on %@thread. Notification called with %@.", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"", timer);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"Attempt to play streaming audio failed.", @"")];
        [alert setMessageText:NSLocalizedString(@"Error", @"")];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        [self saveRadioError:@"Timeout playing."];
        self.timeoutTimer = nil;
        [self stopPressed:nil];
    });
}

#pragma mark -
#pragma mark Other windows/views delegates and actions

- (void)preferencesWindowControllerDidSelect:(PreferencesWindowController *)controller
{
    DLog(@"This is preferencesWindowControllerDidSelect:");
    [self statusItemSetup];
}

- (void)bunniesWindowControllerDidSelect:(BunniesWindowController *)controller withObject:(Bunny *)theBunny
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"bunny" action:@"start" label:@""];
    DLog(@"This is bunniesWindowControllerDidSelect:withObject %@", theBunny);
    self.theSelectedBunny = theBunny;
    // Play the bunny
    dispatch_async(theBunnyQueue, ^{
        [self.theSelectedBunny startRadio:self.currentRadioURL];
    });
}

- (void)bunniesWindowControllerWantsBunnyPlayStopped:(BunniesWindowController *)controller
{
    DLog(@"This is bunniesWindowControllerWantsBunnyPlayStopped:");
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"bunny" action:@"stop" label:@""];
}

- (void)radioListWindowControllerDidSelect:(RadioListWindowController *)controller withObject:(Radio *)radio
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"playFromRadiolist" label:@""];
    DLog(@"radioListWindowControllerDidSelect:withObject: called. Object: <%@>", radio);
    // First implementation. The PFObject should be preserved for further usage
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateInterface];
    });
    self.currentRadioURL = controller.theSelectedStreamURL;
    // Let's see if AAC or MP3
    if([radio.aac_url isEqualToString:@""])
        self.currentRadioRedirectorURL = radio.mp3_url;
    else
        self.currentRadioRedirectorURL = radio.aac_url;
    // Keep around the radio data.
    self.theSelectedRadio = [[radio convertToDictionary] mutableCopy];
    
    // Stop will auto call start if called this way
    if(self.theStreamer.isPlaying)
        [self stopPressed:self];
    else
        [self playPressed:nil];
}

- (void)favoritesWindowControllerDidSelect:(FavoritesWindowController *)controller withObject:(PFObject *)favorite
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"playFromFavorite" label:@""];
    DLog(@"displayFavsViewControllerDidSelect:withObject: called. Object: <%@>", favorite);
    if(favorite[@"radioName"])
        (self.theSelectedRadio)[@"radio_name"] = favorite[@"radioName"];
    // TODO: understand kind of url (MP3 or AAC).
    if(favorite[@"url"])
    {
        (self.theSelectedRadio)[@"aac_url"] = favorite[@"url"];
        (self.theSelectedRadio)[@"mp3_url"] = favorite[@"url"];
    }
    if(favorite[@"info"])
        (self.theSelectedRadio)[@"radio_tags"] = favorite[@"info"];
    (self.theSelectedRadio)[@"radio_url"] = (favorite[@"radio_url"]) ? favorite[@"radio_url"] : @"";
    (self.theSelectedRadio)[@"radio_city"] = (favorite[@"radio_city"]) ? favorite[@"radio_city"] : @"";
    (self.theSelectedRadio)[@"radio_country"] = (favorite[@"radio_country"]) ? favorite[@"radio_country"] : @"";
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateInterface];
    });
    self.currentRadioRedirectorURL = favorite[@"url"];
    // Stop will auto call start if called this way
    DLog(@"Stream is %@playing", self.theStreamer.isPlaying ? @"" : @"NOT ");
    if(self.theStreamer.isPlaying)
    {
        self.currentRadioURL = nil; // that segnal stopPressed to start again from redirector
        [self stopPressed:self];
    }
    else
        [self playFromRedirector:self.currentRadioRedirectorURL];
}

- (void)saveFavoriteWindowControllerDidSelect:(SaveFavoriteWindowController *)controller
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"saveFavorite" label:@""];
    // Save favorite to Parse.
    PFObject *fav = [PFObject objectWithClassName:@"Favorite"];
    fav[@"pUUID"] = [SDCloudUserDefaults stringForKey:@"pUUID"];
    fav[@"radioName"] = (controller.theRadio)[@"radio_name"];
    if([(controller.theRadio)[@"mp3_url"] isEqualToString:@""])
        fav[@"url"] = (controller.theRadio)[@"aac_url"];
    else
        fav[@"url"] = (controller.theRadio)[@"mp3_url"];
    fav[@"info"] = (controller.theRadio)[@"radio_tags"];
    fav[@"radio_url"] = (controller.theRadio)[@"radio_url"];
    fav[@"radio_city"] = (controller.theRadio)[@"radio_city"];
    fav[@"radio_country"] = (controller.theRadio)[@"radio_country"];
    [fav saveInBackground];
    // while we are at it, save the setup and update. :)
    self.theSelectedRadio = controller.theRadio;
    [self updateInterface];
}

-(void)saveRadioError:(NSString *)theError
{
    DLog(@"This is saveRadioError:");
    // Save error to Parse.
    PFObject *err = [PFObject objectWithClassName:@"RadioError"];
    err[@"pUUID"] = [SDCloudUserDefaults stringForKey:@"pUUID"];
    if(self.currentRadioURL)
        err[@"currentRadioURL"] = self.currentRadioURL;
    if(self.currentRadioRedirectorURL)
        err[@"currentRadioRedirectorURL"] = self.currentRadioRedirectorURL;
    err[@"error"] = theError;
    [err saveInBackground];
}

#pragma mark -
#pragma mark Interface Setup

-(void)updateInterface
{
    // Hide web view and disable unuseful things :)
//    [self loadWebViewWithURL:nil];
    self.lyricsButton.enabled = NO;
    if([(self.theSelectedRadio)[@"radio_url"] isEqualToString:@""])
        self.webButton.enabled = NO;
    // reset text
    if((self.theSelectedRadio)[@"radio_name"])
        self.stationInfo.stringValue = self.radioNameDockMenu.title = self.radioNameStatusMenu.title = (self.theSelectedRadio)[@"radio_name"];
    if((self.theSelectedRadio)[@"radio_tags"])
        self.genreInfo.stringValue = (self.theSelectedRadio)[@"radio_tags"];
    self.locationInfo.stringValue = [NSString stringWithFormat:NSLocalizedString(@"from %@, %@", @""), (self.theSelectedRadio)[@"radio_city"], (self.theSelectedRadio)[@"radio_country"]];
    self.metadataInfo.stringValue = self.songTitleDockMenu.title = self.songTitleStatusMenu.title = @"";
    if(self.currentRadioURL)
        self.radioURL.stringValue = self.currentRadioURL;
    self.coverImage = nil;
}

-(void)statusItemSetup
{
    DLog(@"This is statusItemSetup. avoidSysMenu is %ld and theStatusItem is %@", [[NSUserDefaults standardUserDefaults] integerForKey:@"avoidSysMenu"], self.theStatusItem);
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"avoidSysMenu"] == NSOffState && !self.theStatusItem)
    {
        DLog(@"Status menu requested and not already existing. Creating it.");
        // Init the status menu
        NSStatusBar *bar = [NSStatusBar systemStatusBar];
        self.theStatusItem = [bar statusItemWithLength:NSSquareStatusItemLength];
        [self.theStatusItem setImage:[NSImage imageNamed:@"sessionitem-icon"]];
        [self.theStatusItem setHighlightMode:YES];
        [self.theStatusItem setMenu:self.theStatusMenu];
    }
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"avoidSysMenu"] == NSOnState && self.theStatusItem)
    {
        DLog(@"Status menu not requested but already existing. Deleting it.");
        self.theStatusItem = nil;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    // If lyrics button is disabled, disable every menu.
    if([item action] == @selector(loadLyrics:) && !self.lyricsButton.isEnabled)
        return NO;
    if([item action] == @selector(loadRadioWeb:) && !self.webButton.isEnabled)
        return NO;
    if([item action] == @selector(addSong:) && !self.addSongButton.isEnabled)
        return NO;
    return YES;
}


#pragma mark -
#pragma mark Initialization

- (id)initWithWindow:(NSWindow *)window
{
    DLog(@"This is initWithWindow:");
    self = [super initWithWindow:window];
    if (self) {
        NSRect f = window.frame;
        f.size.width  = 320;
        f.size.height = 568+25;
        [window setFrame:f display:YES];
    }
    
    return self;
}

- (void)awakeFromNib
{
    DLog(@"this is awakeFromNib");
    // Set "base" url and radio object and interface
    self.theSelectedRadio = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSDictionary *theLastRadio = [SDCloudUserDefaults dictionaryForKey:@"selectedRadio"];
    NSString *currentRadioURL = [SDCloudUserDefaults stringForKey:@"currentRadioURL"];
    NSString *currentRadioRedirectorURL = [SDCloudUserDefaults stringForKey:@"currentRadioRedirectorURL"];
    if(theLastRadio && currentRadioURL && currentRadioRedirectorURL)
    {
        DLog(@"Last played radio was: %@", theLastRadio);
        self.theSelectedRadio = [theLastRadio mutableCopy];
        self.currentRadioURL = currentRadioURL;
        self.currentRadioRedirectorURL = currentRadioRedirectorURL;
    }
    else
    {
        DLog(@"No last played radio saved, using Radio Paradise.");
        (self.theSelectedRadio)[@"aac_bitrate"] = @128;
        (self.theSelectedRadio)[@"aac_url"] = @"http://www.radioparadise.com/musiclinks/rp_128aac.m3u";
        (self.theSelectedRadio)[@"mp3_bitrate"] = @128;
        (self.theSelectedRadio)[@"mp3_url"] = @"http://www.radioparadise.com/musiclinks/rp_128.m3u";
        (self.theSelectedRadio)[@"radio_city"] = @"Paradise, California";
        (self.theSelectedRadio)[@"radio_country"] = @"US";
        (self.theSelectedRadio)[@"radio_name"] = @"Radio Paradise";
        (self.theSelectedRadio)[@"radio_tags"] = @"Eclectic";
        (self.theSelectedRadio)[@"radio_url"] = @"http://www.radioparadise.com/";
        self.currentRadioURL = @"http://stream-tx1.radioparadise.com:8056"; // This is an Mp3 64K streaming URL, so it's OK for nabaztags :)
        self.currentRadioRedirectorURL = @"http://www.radioparadise.com/musiclinks/rp_128.m3u";
    }
    [self.spinner setBezeled:YES];
    [self updateInterface];
    // Localize interface
    [self.window setTitle:NSLocalizedString(@"Short Wave", nil)];
    [self.saveFavorites setTitle:NSLocalizedString(@"Save", @"")];
    [self.saveFavorites setToolTip:NSLocalizedString(@"Save current radio as a favorite.", nil)];
    [self.lyricsButton setTitle:NSLocalizedString(@"Lyrics", @"")];
    [self.lyricsButton setToolTip:NSLocalizedString(@"Show lyrics for current song in default browser.", nil)];
    [self.webButton setTitle:NSLocalizedString(@"Web", @"")];
    [self.webButton setToolTip:NSLocalizedString(@"Show current radio homepage in default browser.", nil)];
    [self.addSongButton setToolTip:NSLocalizedString(@"Add current song to the list of favorite songs.", nil)];
    [self.songListButton setToolTip:NSLocalizedString(@"Show favorite songs list.", nil)];
    [self.favoritesListButton setToolTip:NSLocalizedString(@"Show favorite radios list.", nil)];
    [self.radioListButton setToolTip:NSLocalizedString(@"Show radio list.", nil)];
    [self.playOrStopButton setToolTip:NSLocalizedString(@"Play (or stop) radio stream.", nil)];
    [self.bunniesButton setToolTip:NSLocalizedString(@"Play (or stop) stream to your Nabaztag and/or Karotz.", nil)];
    // Localize menus
    [self.aboutMenu setTitle:NSLocalizedString(@"About Short Wave", nil)];
    // Make buttons display alternate image when clicked
    [self.aboutButton.cell setHighlightsBy:NSContentsCellMask];
    [self.radioListButton.cell setHighlightsBy:NSContentsCellMask];
    [self.lyricsButton.cell setHighlightsBy:NSContentsCellMask];
    [self.webButton.cell setHighlightsBy:NSContentsCellMask];
    [self.favoritesListButton.cell setHighlightsBy:NSContentsCellMask];
    [self.saveFavorites.cell setHighlightsBy:NSContentsCellMask];
    [self.bunniesButton.cell setHighlightsBy:NSContentsCellMask];
    [self.songListButton.cell setHighlightsBy:NSContentsCellMask];
    [self.addSongButton.cell setHighlightsBy:NSContentsCellMask];
    [self.playOrStopButton.cell setHighlightsBy:NSContentsCellMask];

    // Window size
    DLog(@"self.window: %@", self.window);
    [self.backgroundImage setImageScaling:NSScaleToFit];
    NSRect f = self.window.frame;
    f.size.width  = 320;
    f.size.height = 568+25;
    [self.window setFrame:f display:YES];
    // Setup queues for background operations
    self.imageLoadQueue = [[NSOperationQueue alloc] init];
    theBunnyQueue = dispatch_queue_create("it.iltofa.bunnyqueue", NULL);
    [self statusItemSetup];
}

#pragma mark -
#pragma mark Actions

- (IBAction)playOrStop:(id)sender
{
    if(self.theStreamer.isPlaying)
        [self stopPressed:nil];
    else
        [self playPressed:nil];
}

- (IBAction)bunnyClocked:(id)sender
{
    // Stop if we have a bunny...
    if(self.theSelectedBunny != nil)
    {
        dispatch_async(theBunnyQueue, ^{
            [self.theSelectedBunny stopRadio];
            // reset the bunny
            self.theSelectedBunny = nil;
        });
    }
    else
    {
        if(!self.bunniesController)
        {
            self.bunniesController = [[BunniesWindowController alloc] initWithWindowNibName:@"BunniesWindowController"];
            self.bunniesController.delegate = self;
        }
        [self.bunniesController showWindow:self];
    }
}

- (IBAction)getFavorites:(id)sender
{
    if(!self.favController)
    {
        self.favController = [[FavoritesWindowController alloc] initWithWindowNibName:@"FavoritesWindowController"];
        self.favController.delegate = self;
    }
    [self.favController showWindow:self];
}

- (IBAction)loadLyrics:(id)sender
{
    // TODO: substitute with a WebView
    if(![self.metadataInfo.stringValue isEqualToString:@""])
    {
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"lyrics" label:@""];
        DLog(@"self.metadataInfo.text is %@", self.metadataInfo.stringValue);
        // URL-encode song and artist names
        NSString *temp = self.currentSongName;
        temp = [temp stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        temp = [temp stringByReplacingOccurrencesOfString:@"@" withString:@"%40"];
        temp = [temp stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
        temp = [temp stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
        temp = [temp stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        NSString *baseDDGUrl;
//        if(skippingSearchPage)
            baseDDGUrl = @"https://duckduckgo.com/?q=\\lyrics+%@";
//        else
//            baseDDGUrl = @"https://duckduckgo.com/?q=lyrics+%@";
        NSString *searchURL = [NSString stringWithFormat:baseDDGUrl, temp];
        searchURL = [searchURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        DLog(@"Loading lyrics from <%@>", searchURL);
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:searchURL]];
    }
    else
        self.lyricsButton.enabled = NO;
}

- (IBAction)loadRadioWeb:(id)sender
{
    if(![(self.theSelectedRadio)[@"radio_url"] isEqualToString:@""]) {
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"web" label:@""];
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(self.theSelectedRadio)[@"radio_url"]]];
    }
    else // reset to nothing
        self.webButton.enabled = NO;
}

- (IBAction)saveFavorite:(id)sender
{
    if(!self.saveController)
        self.saveController = [[SaveFavoriteWindowController alloc] initWithWindowNibName:@"SaveFavoriteWindowController"];
    // Refresh radio
    self.saveController.delegate = self;
    self.saveController.theRadio = self.theSelectedRadio;
    [self.saveController configureDefaultRadio];
    [self.saveController showWindow:self];
}

- (IBAction)getRadios:(id)sender
{
    DLog(@"getRadios: pressed.");
    if(!self.listController)
        self.listController = [[RadioListWindowController alloc] initWithWindowNibName:@"RadioListWindowController"];
    self.listController.delegate = self;
    [self.listController showWindow:self];
}

- (IBAction)loadSongList:(id)sender
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"songList" label:@""];
    DLog(@"loadSongList selected");
    if(!self.songListController)
        self.songListController = [[SongListWindowController alloc] initWithWindowNibName:@"SongListWindowController"];
    [self.songListController showWindow:self];
}

- (IBAction)addSong:(id)sender
{
    DLog(@"This is addSong: saving a song.");
    // Recover song data...
    NSArray *songPieces = [self.metadataInfo.stringValue componentsSeparatedByString:@"\n"];
    if([songPieces count] == 2)
    {
        self.addSongButton.enabled = NO;
        // No save for RP metadata filler
        if([songPieces[0] isEqualToString:@"Commercial-free"])
            return;
        DLog(@"Adding song %@ - %@", songPieces[1], songPieces[0]);
        SongAdder *theAdder = [[SongAdder alloc] initWithTitle:songPieces[1] andArtist:songPieces[0] andCoversheet:self.coverImage];
        NSError *err;
        if(![theAdder addSong:&err])
        {
            // An error occurred when saving...
            NSString *temp = [NSString stringWithFormat:NSLocalizedString(@"While saving the song got the error %@, %@", @""), err, [err userInfo]];
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setInformativeText:temp];
            [alert setMessageText:NSLocalizedString(@"Error", @"")];
            [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
            self.addSongButton.enabled = YES;
        }
    }
    else
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"Malformed song name, cannot save it.", @"")];
        [alert setMessageText:NSLocalizedString(@"Error", @"")];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
}

- (IBAction)nukeDB:(id)sender
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setInformativeText:@"This will delete your iCloud data for the application. Are you sure you want to continue?"];
    [alert setMessageText:@"WARNING!"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Continue and Delete"];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)openPreferences:(id)sender
{
    DLog(@"Preferences requested");
    if(!self.preferencesController)
        self.preferencesController = [[PreferencesWindowController alloc] initWithWindowNibName:@"PreferencesWindowController"];
    self.preferencesController.delegate = self;
    [self.preferencesController showWindow:self];
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertSecondButtonReturn)
        [((RadiozAppDelegate *)[[NSApplication sharedApplication] delegate]).coreDataController nukeAndPave];
}


- (void)stopPressed:(id)sender
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"stop" label:@""];
    [self.theStreamer stop];
    [self startSpinner];
    self.playOrStopButton.enabled = NO;
    self.lyricsButton.enabled = NO;
    self.webButton.enabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        DLog(@"setting button to play");
        [self.playOrStopButton setImage:[NSImage imageNamed:@"button-play"]];
        [self.playOrStopButton setAlternateImage:[NSImage imageNamed:@"button-play-clicked"]];
        self.playOrStopMenu.title = self.playOrStopDockMenu.title = self.playOrStopStatusMenu.title = @"Play";
        self.playOrStopButton.enabled = YES;
        self.coverImage = [NSImage imageNamed:@"button-bground"];
        [self stopSpinner:nil];
        self.theStreamer = nil;
        [self updateInterface];
        // if called not from the button (with the stream on), restart the play
        if(sender == self && self.currentRadioURL)
            [self playPressed:nil];
        else if (sender == self) // and currentRadioURL is nil
            [self playFromRedirector:self.currentRadioRedirectorURL];
    });
}


- (IBAction)playPressed:(id)sender
{
    DLog(@"Play pressed");
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"play" label:@""];
    self.radioURL.stringValue = self.currentRadioURL;
    // Disable play button and setup timeout
    self.playOrStopButton.enabled = NO;
    if(self.timeoutTimer) {
        DLog(@"Killing stale timeout timer: %@ on %@thread", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"");
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(killConnectingStream:) userInfo:nil repeats:NO];
    DLog(@"Set timeout timer: %@ on %@thread", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"");
    NSAssert(self.currentRadioURL, @"self.currentRadioUrl not inited.");
    self.theStreamer = [[AudioStreamer alloc] initWithURL:[NSURL URLWithString:self.currentRadioURL]];
    [self startSpinner];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(metadataNotificationReceived:) name:kStreamHasMetadata object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bitrateNotificationReceived:) name:kStreamHasBitrate object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorNotificationReceived:) name:kStreamIsInError object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopSpinner:) name:kStreamConnected object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioNameNotificationreceived:) name:kStreamGotRadioname object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioUrlNotificationreceived:) name:kStreamGotRadioUrl object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bitrateNotificationReceived:) name:kStreamGotGenre object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(streamRedirected:) name:kStreamIsRedirected object:nil];
    [self.theStreamer start];
}

- (void)playFromRedirector:(NSString *)redirectorURL
{
    DLog(@"Starting play for <%@>.", redirectorURL);
    // Disable play button and setup timeout
    self.playOrStopButton.enabled = NO;
    // Now search for audio redirector type of files
    NSArray *values = @[@".m3u", @".pls", @".wax", @".ram", @".pls", @".m4u"];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@" %@ ENDSWITH[cd] SELF ", redirectorURL];
    NSArray * searchResults = [values filteredArrayUsingPredicate:predicate];
    // if an audio redirector is found...
    if([searchResults count] > 0)
    {
        // Now loading the redirector to find the "right" URL
        DLog(@"Loading audio redirector of type %@ from <%@>.", searchResults[0], redirectorURL);
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:redirectorURL]];
        [NSURLConnection sendAsynchronousRequest:req queue:self.imageLoadQueue completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
         {
             if(data && [(NSHTTPURLResponse *)res statusCode] == 200)
             {
                 NSString *redirectorData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 DLog(@"Data from redirector are:\n<%@>", redirectorData);
                 // Now get the URLs
                 NSError *error = NULL;
                 NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
                 NSTextCheckingResult *result = [detector firstMatchInString:redirectorData options:0 range:NSMakeRange(0, [redirectorData length])];
                 if(result && result.range.location != NSNotFound)
                 {
                     DLog(@"Found URL: %@", result.URL);
                     self.currentRadioURL = [result.URL absoluteString];
                     // call the play on main thread
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self playPressed:nil];
                     });
                 }
                 else
                 {
                     NSLog(@"URL not found in redirector.");
                     self.playOrStopButton.enabled = YES;
                 }
             }
             else
             {
                 NSLog(@"Error loading redirector: %@", [err localizedDescription]);
                 self.playOrStopButton.enabled = YES;
             }
         }];
    }
}

@end
