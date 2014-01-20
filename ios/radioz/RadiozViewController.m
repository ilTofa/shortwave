//
//  RadiozViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 12/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadiozViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Parse/Parse.h>
#import "SDCloudUserDefaults.h"
#import "Radio+ToDictionary.h"
#import "SongsViewController.h"
#import "SongAdder.h"
#import "PiwikTracker.h"
#import "InfoViewController.h"

@interface RadiozViewController () <SaveFavViewControllerDelegate, DisplayFavsViewControllerDelegate, BunniesViewControllerDelegate, RadioChooserViewControllerDelegate, UIWebViewDelegate>

@end

@implementation RadiozViewController

#pragma mark -
#pragma mark AudioStream Notifications management

-(void)loadWebViewWithURL:(NSString *)theURL
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(theURL)
        {
            self.theWebView.hidden = NO;
            self.theWebToolbar.hidden = NO;
            [self.theWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:theURL]]];
        }
        else 
        {
            self.goForwardButton.enabled = self.goBackButton.enabled = self.moreButton.enabled = NO;
            self.theWebView.hidden = YES;
            self.theWebToolbar.hidden = YES;
        }
    });
}

-(void)loadLyrics:(BOOL)skippingSearchPage
{
    if(![self.metadataInfo.text isEqualToString:@""])
    {
        DLog(@"self.metadataInfo.text is %@", self.metadataInfo.text);
        [self showWebIfNeeded];
        // URL-encode song and artist names
        NSString *temp = self.currentSongName;
        temp = [temp stringByReplacingOccurrencesOfString:@" " withString:@"+"];
        temp = [temp stringByReplacingOccurrencesOfString:@"@" withString:@"%40"];
        temp = [temp stringByReplacingOccurrencesOfString:@"?" withString:@"%3F"];
        temp = [temp stringByReplacingOccurrencesOfString:@":" withString:@"%3A"];
        temp = [temp stringByReplacingOccurrencesOfString:@"&" withString:@"%26"];
        NSString *baseDDGUrl;
        if(skippingSearchPage)
            baseDDGUrl = @"https://duckduckgo.com/?q=\\lyrics+%@";
        else
            baseDDGUrl = @"https://duckduckgo.com/?q=lyrics+%@";
        NSString *searchURL = [NSString stringWithFormat:baseDDGUrl, temp];
        searchURL = [searchURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        self.moreButton.enabled = YES;
        DLog(@"Loading lyrics from <%@>", searchURL);
        [self loadWebViewWithURL:searchURL];
    }
    else // reset to nothing
    {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            self.webSelector.selectedSegmentIndex = 2;
            [self.webSelector setEnabled:NO forSegmentAtIndex:0];
        }
        else
            self.lyricsButton.enabled = NO;
        [self loadWebViewWithURL:nil];
    }
}

-(void)loadRadioWeb
{
    if(![(self.theSelectedRadio)[@"radio_url"] isEqualToString:@""])
    {
        [self showWebIfNeeded];
        self.moreButton.enabled = NO;
        [self loadWebViewWithURL:(self.theSelectedRadio)[@"radio_url"]];
    }
    else // reset to nothing
    {
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
        self.webSelector.selectedSegmentIndex = 2;
        [self.webSelector setEnabled:NO forSegmentAtIndex:1];
        }
        else
            self.webButton.enabled = NO;
        [self loadWebViewWithURL:nil];
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
	self.genreInfo.text = temp;
}

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
                          self.coverImage = [UIImage imageWithData:data];
                          if(self.coverImage != nil)
                          {
                              MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:self.coverImage];
                              NSString *artist = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo][MPMediaItemPropertyArtist];
                              if(!artist)
                                  artist = @"";
                              NSString *title = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo][MPMediaItemPropertyTitle];
                              if(!title)
                                  title = @"";
                              NSDictionary *mpInfo;
                              mpInfo = @{MPMediaItemPropertyAlbumTitle: (self.theSelectedRadio)[@"radio_name"],
                          MPMediaItemPropertyArtist: artist,
                          MPMediaItemPropertyTitle: title,
                          MPMediaItemPropertyArtwork: albumArt,
                          MPMediaItemPropertyGenre: (self.theSelectedRadio)[@"radio_tags"]};
                              [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mpInfo];
                              DLog(@"set MPNowPlayingInfoCenter (from iTunes) to \"%@ - %@\"", mpInfo[MPMediaItemPropertyArtist], mpInfo[MPMediaItemPropertyTitle]);
                          }
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
                    NSDictionary *mpInfo;
                    self.coverImage = [UIImage imageNamed:@"OldRadio"];
                    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:self.coverImage];
                    mpInfo = @{MPMediaItemPropertyAlbumTitle: (self.theSelectedRadio)[@"radio_name"],
                MPMediaItemPropertyArtist: tempArtist,
                MPMediaItemPropertyTitle: tempTitle,
                MPMediaItemPropertyArtwork: albumArt,
                MPMediaItemPropertyGenre: (self.theSelectedRadio)[@"radio_tags"]};
                    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mpInfo];
                    DLog(@"set MPNowPlayingInfoCenter (with album) to \"%@ - %@\"", mpInfo[MPMediaItemPropertyArtist], mpInfo[MPMediaItemPropertyTitle]);
                    temp = [NSString stringWithFormat:@"%@\n%@", tempArtist, tempTitle];
                    // We (probably) have track titles, enable lyrics and add song buttons
                    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                        [self.webSelector setEnabled:YES forSegmentAtIndex:0];
                    else
                        self.lyricsButton.enabled = YES;
                    self.addSongButton.enabled = YES;
                    // if user is already reading lyrics, let's them update!
                    if(self.theWebView.isHidden == NO)
                        [self loadLyrics:YES];
                    // Let's try to load coverart (after a couple second to give time to the StreamUrl processing)
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                        [self getCoverImageFromItunesStore:[NSString stringWithFormat:@"%@ %@", tempArtist, tempTitle]];
                    });
                }
                else
                    DLog(@"Malformed StreamTitle informations: \"%@\"", temp);
            }
            if([temp length] > 0 && [temp characterAtIndex:0] != '<')
                self.metadataInfo.text = temp;
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
                     self.coverImage = [UIImage imageWithData:data];
                     if(self.coverImage != nil)
                     {
                         self.isCoverArtAlreadyLoaded = YES;
                         [[PiwikTracker sharedInstance] sendEventWithCategory:@"radio" action:@"StreamUrlReceived" label:self.stationInfo.text];
                         MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:self.coverImage];
                         NSString *artist = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo][MPMediaItemPropertyArtist];
                         if(!artist)
                             artist = @"";
                         NSString *title = [[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo][MPMediaItemPropertyTitle];
                         if(!title)
                             title = @"";
                         NSDictionary *mpInfo;
                         mpInfo = @{MPMediaItemPropertyAlbumTitle: (self.theSelectedRadio)[@"radio_name"], 
                                   MPMediaItemPropertyArtist: artist,   
                                   MPMediaItemPropertyTitle: title,  
                                   MPMediaItemPropertyArtwork: albumArt,
                                   MPMediaItemPropertyGenre: (self.theSelectedRadio)[@"radio_tags"]};
                         [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mpInfo];
                         DLog(@"set MPNowPlayingInfoCenter (with coverart) to \"%@ - %@\"", mpInfo[MPMediaItemPropertyArtist], mpInfo[MPMediaItemPropertyTitle]);
                     }
                 }
             }];
        }
    }
}

-(void)radioNameNotificationreceived:(NSNotification *)note
{
    DLog(@"Got the station name: \"%@\"", self.theStreamer.streamRadioName);
    self.stationInfo.text = self.theStreamer.streamRadioName;
    (self.theSelectedRadio)[@"radio_name"] = self.theStreamer.streamRadioName;
}

-(void)radioUrlNotificationreceived:(NSNotification *)note
{
    // Now get the URLs
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:&error];
    NSTextCheckingResult *result = [detector firstMatchInString:self.theStreamer.streamRadioUrl options:0 range:NSMakeRange(0, [self.theStreamer.streamRadioUrl length])];
    if(result && result.range.location != NSNotFound)
    {
        DLog(@"Found radioURL: <%@>", result.URL);
        (self.theSelectedRadio)[@"radio_url"] = [result.URL absoluteString];
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            [self.webSelector setEnabled:YES forSegmentAtIndex:1];
            if(self.webSelector.selectedSegmentIndex == 1)
                [self loadRadioWeb];
        }
        else
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
        [self.spinner stopAnimating];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Attempt to play streaming audio failed.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles: nil];
        [alert show];
        [self saveRadioError:@"Attempt to play streaming audio failed."];
        [self stopPressed:nil];
    });
}

-(void)streamRedirected:(NSNotification *)note
{
	NSLog(@"Stream Redirected.");
    self.radioURL.text = self.currentRadioURL = [self.theStreamer.url absoluteString];
    [self stopPressed:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
        [self playPressed:nil];
    });
}

-(void) startSpinner
{
    self.view.userInteractionEnabled = NO;
    [self.spinner startAnimating];
}

-(void)stopSpinner:(NSNotification *)note
{
    self.view.userInteractionEnabled = YES;
    [self.spinner stopAnimating];
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
            [self.playOrStopButton setImage:[UIImage imageNamed:@"button-stop"] forState:UIControlStateNormal];
            [self.playOrStopButton setImage:[UIImage imageNamed:@"button-stop"] forState:UIControlStateHighlighted];
            [self.playOrStopButton setImage:[UIImage imageNamed:@"button-stop"] forState:UIControlStateSelected];        
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
    DLog(@"This is a timeout timer.");
    dispatch_async(dispatch_get_main_queue(), ^{
        DLog(@"This is the timeout timer: %@ on %@thread. Notification called with %@.", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"", timer);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Attempt to play streaming audio failed.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles: nil];
        [alert show];
        [self saveRadioError:@"Timeout playing."];
        self.timeoutTimer = nil;
        [self stopPressed:nil];
    });
}

-(void)nowPlayingHandler
{
    NSDictionary *mpInfo;
    mpInfo = @{MPMediaItemPropertyAlbumTitle: (self.theSelectedRadio)[@"radio_name"], 
              MPMediaItemPropertyTitle: self.currentSongName,   
              MPMediaItemPropertyGenre: (self.theSelectedRadio)[@"radio_tags"]};   
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = mpInfo;
}

-(void)saveRadioError:(NSString *)theError
{
    // Save favorite to Parse.
    PFObject *err = [PFObject objectWithClassName:@"RadioError"];
    err[@"pUUID"] = [SDCloudUserDefaults stringForKey:@"pUUID"];
    if(self.currentRadioURL)
        err[@"currentRadioURL"] = self.currentRadioURL;
    if(self.currentRadioRedirectorURL)
        err[@"currentRadioRedirectorURL"] = self.currentRadioRedirectorURL;
    err[@"error"] = theError;
    [err saveEventually];
}

#pragma mark -
#pragma mark RadioChooserViewControllerDelegate implementation


- (void)radioChooserViewControllerDidCancel:(RadioChooserViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)radioChooserViewControllerDidSelect:(RadioChooserViewController *)controller withObject:(Radio *)radio
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"playFromRadiolist" label:@""];
    DLog(@"radioChooserViewControllerDidSelect:withObject: called. Object: <%@>", radio);
    // First implementation. The PFObject should be preserved for further usage
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateInterfaceWhilePreservingMetadata:NO];
    });
    self.currentRadioURL = controller.theSelectedStreamURL;
    // Let's see if AAC or MP3
    if([radio.aac_url isEqualToString:@""])
        self.currentRadioRedirectorURL = radio.mp3_url;
    else
        self.currentRadioRedirectorURL = radio.aac_url;
    // Keep around the radio data.
    self.theSelectedRadio = [[radio convertToDictionary] mutableCopy];

    [self radioChooserViewControllerDidCancel:controller];
    // Stop will auto call start if called this way
    if(self.theStreamer.isPlaying)
        [self stopPressed:self];
    else
        [self playPressed:nil];
    
}

#pragma mark -
#pragma mark DisplayFavsViewControllerDelegate implementation

- (void)displayFavsViewControllerDidCancel:(DisplayFavsViewController *)controller;
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([self.popSegue.popoverController isPopoverVisible])
            [self.popSegue.popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)displayFavsViewControllerDidSelect:(DisplayFavsViewController *)controller withObject:(PFObject *)favorite;
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
        [self updateInterfaceWhilePreservingMetadata:NO];
    });
    self.currentRadioRedirectorURL = favorite[@"url"];
    [self displayFavsViewControllerDidCancel:controller];
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

#pragma mark -
#pragma mark SaveFavViewControllerDelegate implementation

- (void)saveFavViewControllerDidCancel:(SaveFavViewController *)controller;
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([self.popSegue.popoverController isPopoverVisible])
            [self.popSegue.popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)saveFavViewControllerDidSelect:(SaveFavViewController *)controller;
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
    
    [fav saveEventually];
    
    // while we are at it, save the setup and update. :)
    self.theSelectedRadio = controller.theRadio;
    [self updateInterfaceWhilePreservingMetadata:YES];
    
    [self saveFavViewControllerDidCancel:controller];
}

#pragma mark -
#pragma mark BunniesViewControllerDelegate implementation

- (void)bunniesViewControllerDidCancel:(BunniesViewController *)controller
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ([self.popSegue.popoverController isPopoverVisible])
            [self.popSegue.popoverController dismissPopoverAnimated:YES];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)bunniesViewControllerDidSelect:(BunniesViewController *)controller withObject:(Bunny *)theBunny;
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"bunny" action:@"start" label:@""];
    // Set the bunny
    self.theSelectedBunny = theBunny;
    // Play the bunny
    dispatch_async(theBunnyQueue, ^{
        // Disable idle detection if Karotz is selected.
        if(self.theSelectedBunny.isKarotz)
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        [self.theSelectedBunny startRadio:self.currentRadioURL];
    });
    [self bunniesViewControllerDidCancel:controller];
}

- (void)bunniesViewControllerWantsBunnyPlayStopped:(BunniesViewController *)controller
{
    DLog(@"bunniesViewControllerWantsBunnyPlayStopped: called");
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"bunny" action:@"stop" label:@""];
    if(self.theSelectedBunny != nil)
    {
        dispatch_async(theBunnyQueue, ^{
            // Eventually restore idle timer.
            [UIApplication sharedApplication].idleTimerDisabled = NO;
            [self.theSelectedBunny stopRadio];
            // reset the bunny
            self.theSelectedBunny = nil;
        });
    }
}

#pragma mark -
#pragma mark Actions

- (void)playPressed:(id)sender 
{
    self.radioURL.text = self.currentRadioURL;
    // Disable play button and setup timeout
    self.playOrStopButton.enabled = NO;
    if(self.timeoutTimer) {
        DLog(@"Killing stale timeout timer: %@ on %@thread", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"");
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(killConnectingStream:) userInfo:nil repeats:NO];
    DLog(@"Set timeout timer: %@ on %@thread", self.timeoutTimer, [NSThread isMainThread] ? @"main " : @"");
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationChangedState:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    NSDictionary *mpInfo;
    self.coverImage = [UIImage imageNamed:@"OldRadio"];
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:self.coverImage];
    mpInfo = @{MPMediaItemPropertyAlbumTitle: (self.theSelectedRadio)[@"radio_name"],
               MPMediaItemPropertyArtwork: albumArt,
               MPMediaItemPropertyGenre: (self.theSelectedRadio)[@"radio_tags"]};
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = mpInfo;
    DLog(@"set MPNowPlayingInfoCenter (default infos) to \"%@ - %@\"", mpInfo[MPMediaItemPropertyArtist], mpInfo[MPMediaItemPropertyTitle]);
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
                 NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:&error];
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

- (void)stopPressed:(id)sender 
{
    [self.theStreamer stop];
    [self startSpinner];
    self.playOrStopButton.enabled = NO;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [self.webSelector setEnabled:NO forSegmentAtIndex:0];
        [self.webSelector setEnabled:NO forSegmentAtIndex:1];
    }
    else
    {
        self.lyricsButton.enabled = NO;
        self.webButton.enabled = NO;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamHasMetadata object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamHasBitrate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamIsInError object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamConnected object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamGotRadioname object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamGotRadioUrl object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamGotGenre object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStreamIsRedirected object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        DLog(@"setting button to play");
        [self.playOrStopButton setImage:[UIImage imageNamed:@"button-play"] forState:UIControlStateNormal];
        [self.playOrStopButton setImage:[UIImage imageNamed:@"button-play"] forState:UIControlStateHighlighted];
        [self.playOrStopButton setImage:[UIImage imageNamed:@"button-play"] forState:UIControlStateSelected];
        self.playOrStopButton.enabled = YES;
        self.addSongButton.enabled = NO;
        [self stopSpinner:nil];
        self.theStreamer = nil;
        // if called not from the button (with the stream on), restart the play
        if(sender == self && self.currentRadioURL)
            [self playPressed:nil];
        else if (sender == self) // and currentRadioURL is nil
            [self playFromRedirector:self.currentRadioRedirectorURL];
    });
}

- (IBAction)playOrStop:(id)sender
{
    if(self.theStreamer.isPlaying)
        [self stopPressed:nil];
    else
        [self playPressed:nil];
}

- (IBAction)webSelectorClicked:(id)sender 
{
    // Stop eventual loadings and load the new URL
    if(self.theWebView.isLoading)
        [self.theWebView stopLoading];
    switch (self.webSelector.selectedSegmentIndex) 
    {
        case 0:
            [self loadLyrics:YES];
            break;            
        case 1:
            [self loadRadioWeb];
            break;
        default:
            [self loadWebViewWithURL:nil];
            break;
    }
}

- (IBAction)gotoSafari:(id)sender 
{
    [[UIApplication sharedApplication] openURL:self.theWebView.request.URL];
}

- (IBAction)lyricsClicked:(id)sender
{
    // Stop eventual loadings and load the new URL
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"lyrics" label:@""];
    if(self.theWebView.isLoading)
        [self.theWebView stopLoading];
    [self loadLyrics:YES];
}

- (IBAction)webClicked:(id)sender
{
    // Stop eventual loadings and load the new URL
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"web" label:@""];
    if(self.theWebView.isLoading)
        [self.theWebView stopLoading];
    [self loadRadioWeb];
}

- (IBAction)songListClocked:(id)sender
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"songList" label:@""];
    SongsViewController *theSongsBox = [[SongsViewController alloc] initWithNibName:@"SongsViewController" bundle:[NSBundle mainBundle]];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        theSongsBox.modalPresentationStyle = UIModalPresentationPageSheet;
    else
        theSongsBox.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:theSongsBox animated:YES completion:nil];
    theSongsBox = nil;
}

- (IBAction)addSongClicked:(id)sender
{
    // Recover song data...
    NSArray *songPieces = [self.metadataInfo.text componentsSeparatedByString:@"\n"];
    if([songPieces count] == 2)
    {
        self.addSongButton.enabled = NO;
        // No save for RP metadata filler
        if([songPieces[0] isEqualToString:@"Commercial-free"])
            return;
        SongAdder *theAdder = [[SongAdder alloc] initWithTitle:songPieces[1] andArtist:songPieces[0] andCoversheet:self.coverImage];
        NSError *err;
        if(![theAdder addSong:&err])
        {
            // An error occurred when saving...
            NSString *temp = [NSString stringWithFormat:NSLocalizedString(@"While saving the song got the error %@, %@", @""), err, [err userInfo]];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:temp delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles: nil];
            [alert show];
            self.addSongButton.enabled = YES;
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:NSLocalizedString(@"Malformed song name, cannot save it.", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles: nil];
        [alert show];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    DLog(@"prepareForSegue called for %@", [segue identifier]);
    if ([[segue identifier] isEqualToString:@"SaveFavorite"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        SaveFavViewController *saveController = [navigationController viewControllers][0];
        saveController.delegate = self;
        saveController.theRadio = self.theSelectedRadio;
        // segue is a popover, we have to explicitly call initialization routine and save the popover
        self.popSegue = (UIStoryboardPopoverSegue*)segue;
        [saveController configureView];
    }
    if ([[segue identifier] isEqualToString:@"SaveFavoriteIPhone"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        SaveFavViewController *saveController = [navigationController viewControllers][0];
        saveController.delegate = self;
        saveController.theRadio = self.theSelectedRadio;
        [saveController configureView];
    }
    if ([[segue identifier] isEqualToString:@"Favorites"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        DisplayFavsViewController *displayFavsController = [navigationController viewControllers][0];
        displayFavsController.delegate = self;
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            // segue is a popover on iPad, we have to save the popover
            self.popSegue = (UIStoryboardPopoverSegue*)segue;
    }
    if ([[segue identifier] isEqualToString:@"Conigli"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        BunniesViewController *displayBunniesController = [navigationController viewControllers][0];
        displayBunniesController.delegate = self;
        // segue is a popover, we have to save the popover
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            // segue is a popover on iPad, we have to save the popover
            self.popSegue = (UIStoryboardPopoverSegue*)segue;
    }
    if ([[segue identifier] isEqualToString:@"RadioChooser"])
    {
        UINavigationController *navigationController = segue.destinationViewController;
        RadioChooserViewController *radioChooserController = [navigationController viewControllers][0];
        radioChooserController.delegate = self;
    }
}

#pragma mark -
#pragma mark Interface Setup

-(void)updateInterfaceWhilePreservingMetadata:(BOOL)preserveMetadata
{
    // Hide web view and disable unuseful things :)
    [self loadWebViewWithURL:nil];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [self.webSelector setEnabled:NO forSegmentAtIndex:0];
        if([(self.theSelectedRadio)[@"radio_url"] isEqualToString:@""])
            [self.webSelector setEnabled:NO forSegmentAtIndex:1];
    }
    else
    {
        self.lyricsButton.enabled = NO;
        if([(self.theSelectedRadio)[@"radio_url"] isEqualToString:@""])
            self.webButton.enabled = NO;
    }
    // reset text
    self.stationInfo.text = (self.theSelectedRadio)[@"radio_name"];
    self.genreInfo.text = (self.theSelectedRadio)[@"radio_tags"];
    self.locationInfo.text = [NSString stringWithFormat:NSLocalizedString(@"from %@, %@", @""), (self.theSelectedRadio)[@"radio_city"], (self.theSelectedRadio)[@"radio_country"]];
    if(!preserveMetadata)
        self.metadataInfo.text = @"";
    self.radioURL.text = self.currentRadioURL;
}

-(void)customizeSlider:(UISlider *)slider
{
//    [slider setMinimumTrackImage:[UIImage imageNamed:@"Sx-volume"] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage imageNamed:@"Dx-Volume"] forState:UIControlStateNormal];
    [slider setMaximumTrackImage:[UIImage imageNamed:@"Dx-Volume"] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"Pomello-volume"] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"Pomello-volume"] forState:UIControlStateHighlighted];

}

-(void)customizeAirplayButton:(UIButton *)button
{
    self.airplayButton = button; // @property retain
    [self.airplayButton setImage:[UIImage imageNamed:@"button-airplay"] forState:UIControlStateNormal];
//    [self.airplayButton setBounds:CGRectMake(0, 0, kDefaultIconSize, kDefaultIconSize)];
    [self.airplayButton addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([object isKindOfClass:[UIButton class]] && [[change valueForKey:NSKeyValueChangeNewKey] intValue] == 1) {
        [(UIButton *)object setImage:[UIImage imageNamed:@"button-airplay"] forState:UIControlStateNormal];
//        [(UIButton *)object setBounds:CGRectMake(0, 0, kDefaultIconSize, kDefaultIconSize)];
    }
}

#pragma mark -
#pragma mark LoadUnload

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Set "base" url and radio object and interface
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if([UIScreen mainScreen].bounds.size.height == 568.0f)
            self.iPhoneBackgroundImage.image = [UIImage imageNamed:@"Default-568h"];
        else
            self.iPhoneBackgroundImage.image = [UIImage imageNamed:@"Default"];
    }
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
    [self updateInterfaceWhilePreservingMetadata:NO];
    // Prepare for background audio
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[AVAudioSession sharedInstance] setDelegate:self];

    // Localize interface
    self.moreButton.title = NSLocalizedString(@"More", @"");
    [self.saveFavorites setTitle:NSLocalizedString(@"Save", @"") forState:UIControlStateNormal];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        NSDictionary *attributes = @{UITextAttributeFont: [UIFont fontWithName:@"Georgia" size:18.0],
                                    UITextAttributeTextColor: [UIColor colorWithRed:26.0/255.0 green:15.0/255.0 blue:6.0/255.0 alpha:1.0],
                                    UITextAttributeTextShadowColor: [UIColor clearColor],
                                    UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)]};
        [self.webSelector setTitleTextAttributes:attributes forState:UIControlStateNormal];
        
        attributes = @{UITextAttributeFont: [UIFont fontWithName:@"Georgia" size:18.0],
    UITextAttributeTextColor: [UIColor colorWithRed:242.0/255.0 green:228.0/255.0 blue:189.0/255.0 alpha:1.0],
    UITextAttributeTextShadowColor: [UIColor clearColor],
    UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, 1)]};
        [self.webSelector setTitleTextAttributes:attributes forState:UIControlStateDisabled];

        [self.webSelector setTitle:NSLocalizedString(@"Lyrics", @"") forSegmentAtIndex:0];
        [self.webSelector setTitle:NSLocalizedString(@"Web", @"") forSegmentAtIndex:1];
        [self.webSelector setTitle:NSLocalizedString(@"Speaker", @"") forSegmentAtIndex:2];
    }
    else
    {
        [self.lyricsButton setTitle:NSLocalizedString(@"Lyrics", @"") forState:UIControlStateNormal];
        [self.webButton setTitle:NSLocalizedString(@"Web", @"") forState:UIControlStateNormal];
    }
    
    
    // Add the volume (fake it on simulator)
    self.volumeViewContainer.backgroundColor = [UIColor clearColor];
    UISlider *myVolumeView = nil;
    if (!TARGET_IPHONE_SIMULATOR)
    {
        MPVolumeView *realVolumeView = [[MPVolumeView alloc] initWithFrame:self.volumeViewContainer.bounds];
        [self.volumeViewContainer addSubview: realVolumeView];
        // now find the slider...
        for (id current in realVolumeView.subviews)
        {
            if ([current isKindOfClass:[UISlider class]])
                [self customizeSlider:current];
            if ([current isKindOfClass:[UIButton class]])
                [self customizeAirplayButton:current];
        }
        realVolumeView = nil;
    }
    else
    {
        myVolumeView = [[UISlider alloc] initWithFrame:self.volumeViewContainer.bounds];
        myVolumeView.value = 0.5;
        [self customizeSlider:myVolumeView];
        [self.volumeViewContainer addSubview: myVolumeView];
        myVolumeView = nil;
    }
    
    self.imageLoadQueue = [[NSOperationQueue alloc] init];
    theBunnyQueue = dispatch_queue_create("it.iltofa.bunnyqueue", NULL);
}

- (void)viewDidUnload
{
    [self.airplayButton removeObserver:self forKeyPath:@"alpha"];
    [self setRadioURL:nil];
    [self setStationInfo:nil];
    [self setMetadataInfo:nil];
    [self setSpinner:nil];
    [self setVolumeViewContainer:nil];
    [self setGenreInfo:nil];
    [self.imageLoadQueue cancelAllOperations];
    [self setImageLoadQueue:nil];
    dispatch_release(theBunnyQueue);
    [self setPlayOrStopButton:nil];
    [self setTheWebView:nil];
    [self setWebSelector:nil];
    [self setTheWebToolbar:nil];
    [self setSaveFavorites:nil];
    [self setTheWebOverlayImage:nil];
    [self setMaxMinButton:nil];
    [self setLocationInfo:nil];
    [self setWebButton:nil];
    [self setLyricsButton:nil];
    [self setAddSongButton:nil];
    [self setTheSpinnerForWebView:nil];
    [self setIPhoneBackgroundImage:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    [[AVAudioSession sharedInstance] setDelegate:nil];
    [super viewDidUnload];
}

#pragma mark -
#pragma mark Backgrounding and Multimedia Remote Control

// If interrupted by a call, set interface to stop (user will restart if willing to)
- (void)beginInterruption
{
    // Process stop request.
    DLog(@"This is the beginInterruption handler");    
    if(self.theStreamer.isPlaying)
    {
        [self stopPressed:nil];
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"interruptedWhileStreaming" label:@""];
    }
}

-(void)applicationChangedState:(NSNotification *)note
{
    DLog(@"applicationChangedState: %@", note.name);
    if([note.name isEqualToString:UIApplicationDidEnterBackgroundNotification])
        dispatch_async(dispatch_get_main_queue(), ^{
            [self loadWebViewWithURL:nil];
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                self.webSelector.selectedSegmentIndex = 2;
            // If backgrounding during play, don't quit Localytics session
            if(self.theStreamer.isPlaying)
            {
                DLog(@"Backgrounding while playing");
                [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"backgrounding" label:@""];
            }
            // We would like to receive starts and stops
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            [self becomeFirstResponder];
        });
    if([note.name isEqualToString:UIApplicationWillEnterForegroundNotification])
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.theStreamer.isPlaying)
            {
                DLog(@"In Foreground while Playing");
                [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"foregrounding" label:@""];
            }
            [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
            [self resignFirstResponder];
        });
}

- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent 
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) 
        {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if(self.theStreamer.isPlaying) {
                    DLog(@"Stop received while in background");
                    [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"stopFromRemote" label:@""];
                } else {
                    DLog(@"Play received while in background");
                    [[PiwikTracker sharedInstance] sendEventWithCategory:@"event" action:@"playFromRemote" label:@""];
                }                
                [self playOrStop: nil];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                break;
            default:
                break;
        }
    }
}

- (BOOL) canBecomeFirstResponder 
{
    return YES;
}

#pragma mark -
#pragma mark UIWebViewDelegate and actions

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.theSpinnerForWebView stopAnimating];
    self.goForwardButton.enabled = [self.theWebView canGoForward];
    self.goBackButton.enabled = [self.theWebView canGoBack];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.theSpinnerForWebView startAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"Error: %@", [error description]);
    [self webViewDidFinishLoad:webView];
}

- (IBAction)goBackClicked:(id)sender 
{
    [self.theWebView goBack];
}

- (IBAction)goForwardClicked:(id)sender 
{
    [self.theWebView goForward];
}

- (IBAction)moreClicked:(id)sender
{
    [self loadLyrics:NO];
}

- (IBAction)readability:(id)sender 
{
    [self.theWebView stringByEvaluatingJavaScriptFromString:kReadabilityBookmarkletCode];
}

- (void)showWebIfNeeded
{
    // Only if the web view is not here...
    if(![self.webViewIsMaximized boolValue])
    {
        self.webViewIsMaximized = @YES;
        self.theWebView.alpha = self.theWebToolbar.alpha = 0.0;
        self.theWebView.hidden = self.theWebToolbar.hidden = NO;
        [UIView animateWithDuration:0.7
                         animations:^(void) {
                             self.theWebView.alpha = self.theWebToolbar.alpha = 1.0;
                         } 
                         completion:^(BOOL finished) {
                         }];
    }
}

- (IBAction)maxMinimize:(id)sender 
{
    // If maximized
    if([self.webViewIsMaximized boolValue])
    {   // This hides the webview (and the toolbar) and reset the switcher
        self.webViewIsMaximized = @NO;
        self.theWebView.alpha = self.theWebToolbar.alpha = 1.0;
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.webSelector.selectedSegmentIndex = 2;
        [UIView animateWithDuration:0.7
                         animations:^(void) {
                             self.theWebView.alpha = self.theWebToolbar.alpha = 0.0;
                         } 
                         completion:^(BOOL finished) {
                             self.theWebView.hidden = self.theWebToolbar.hidden = YES;
                             [self loadWebViewWithURL:nil];
                         }];
    }
    else
    {   // This shows the webview (and the toolbar)
        self.webViewIsMaximized = @YES;
        self.theWebView.alpha = self.theWebToolbar.alpha = 0.0;
        self.theWebView.hidden = self.theWebToolbar.hidden = NO;
        [UIView animateWithDuration:0.7
                         animations:^(void) {
                             self.theWebView.alpha = self.theWebToolbar.alpha = 1.0;
                         } 
                         completion:^(BOOL finished) {
                         }];
    }
}

#pragma mark -
#pragma mark autoRotation management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || interfaceOrientation == UIInterfaceOrientationPortrait);
    }
}

/*
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration 
{
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) 
        {
            self.theWebView.frame = CGRectMake(0, 44, 1024, 516);
            self.theWebOverlayImage.frame = CGRectMake(0, 0, 1024, 560);
        } 
        else 
        {
            self.theWebView.frame = CGRectMake(0, 44, 768, 773);
            self.theWebOverlayImage.frame = CGRectMake(0, 0, 768, 817);
        }
    }
}
*/

@end
