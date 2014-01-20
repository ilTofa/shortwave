//
//  RadiozViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 12/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>
#include <QuartzCore/QuartzCore.h>

#import "AudioStreamer.h"
#import "SaveFavViewController.h"
#import "DisplayFavsViewController.h"
#import "RadioChooserViewController.h"
#import "BunniesViewController.h"
#import "Bunny.h"

#define kSearchUrl @"https://duckduckgo.com/?q=%5Clyrics+%@"

#define kReadabilityBookmarkletCode @"(function(){window.baseUrl='https://www.readability.com';window.readabilityToken='';var s=document.createElement('script');s.setAttribute('type','text/javascript');s.setAttribute('charset','UTF-8');s.setAttribute('src',baseUrl+'/bookmarklet/read.js');document.documentElement.appendChild(s);})()"

// #define kReadabilityBookmarkletCode @"function iptxt(){var d=document;try{if(!d.body)throw(0);window.location='http://www.instapaper.com/text?u='+encodeURIComponent(d.location.href);}catch(e){alert('Please wait until the page has loaded.');}}iptxt();void(0)"

@interface RadiozViewController : UIViewController
{
    dispatch_queue_t theBunnyQueue;
}

@property (weak, nonatomic) IBOutlet UILabel *radioURL;
@property (weak, nonatomic) IBOutlet UILabel *stationInfo;
@property (weak, nonatomic) IBOutlet UILabel *metadataInfo;
@property (weak, nonatomic) IBOutlet UILabel *genreInfo;
@property (weak, nonatomic) IBOutlet UILabel *locationInfo;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIView *volumeViewContainer;
@property (strong, nonatomic) NSOperationQueue *imageLoadQueue;
@property (weak, nonatomic) IBOutlet UIButton *playOrStopButton;
@property (weak, nonatomic) IBOutlet UIWebView *theWebView;
@property (weak, nonatomic) IBOutlet UIImageView *theWebOverlayImage;
@property (weak, nonatomic) IBOutlet UISegmentedControl *webSelector;
@property (weak, nonatomic) IBOutlet UIToolbar *theWebToolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goBackButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *goForwardButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *saveFavorites;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *maxMinButton;
@property (weak, nonatomic) IBOutlet UIButton *webButton;
@property (weak, nonatomic) IBOutlet UIButton *lyricsButton;
@property (weak, nonatomic) IBOutlet UIButton *addSongButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *theSpinnerForWebView;
@property (weak, nonatomic) IBOutlet UIImageView *iPhoneBackgroundImage;

@property (weak, nonatomic) UIButton *airplayButton;

@property (copy, nonatomic) NSString *currentRadioURL;
@property (copy, nonatomic) NSString *currentStationURL;
@property (copy, nonatomic) NSString *currentSongName;
@property (copy, nonatomic) NSString *currentRadioRedirectorURL;
@property (strong, nonatomic) UIImage *coverImage;
@property (nonatomic) BOOL isCoverArtAlreadyLoaded;

@property (strong, nonatomic) NSMutableDictionary *theSelectedRadio;

@property (strong, nonatomic) UIStoryboardPopoverSegue* popSegue;

@property (strong, nonatomic) AudioStreamer *theStreamer;
@property (strong, nonatomic) Bunny *theSelectedBunny;
@property (strong, nonatomic) NSNumber *webViewIsMaximized;

@property (strong, nonatomic) NSTimer *timeoutTimer;

- (IBAction)playOrStop:(id)sender;
- (IBAction)webSelectorClicked:(id)sender;
- (IBAction)goBackClicked:(id)sender;
- (IBAction)goForwardClicked:(id)sender;
- (IBAction)moreClicked:(id)sender;
- (IBAction)readability:(id)sender;
- (IBAction)maxMinimize:(id)sender;
- (IBAction)gotoSafari:(id)sender;
- (IBAction)lyricsClicked:(id)sender;
- (IBAction)webClicked:(id)sender;
- (IBAction)songListClocked:(id)sender;
- (IBAction)addSongClicked:(id)sender;

@end
