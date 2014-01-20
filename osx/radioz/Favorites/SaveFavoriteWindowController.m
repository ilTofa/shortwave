//
//  SaveFavoriteWindowController.m
//  radioz
//
//  Created by Giacomo Tufano on 03/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "SaveFavoriteWindowController.h"

@interface SaveFavoriteWindowController ()

@end

@implementation SaveFavoriteWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)configureDefaultRadio
{
    // init
    self.window.backgroundColor = [NSColor colorWithDeviceRed:240.0/255.0 green:198.0/255.0 blue:150.0/255.0 alpha:1.0];
    self.radioNameInput.stringValue = (self.theRadio)[@"radio_name"];
    if([(self.theRadio)[@"mp3_url"] isEqualToString:@""])
        self.urlInput.stringValue = (self.theRadio)[@"aac_url"];
    else
        self.urlInput.stringValue = (self.theRadio)[@"mp3_url"];
    self.infoInput.stringValue = (self.theRadio)[@"radio_tags"];
    self.radioUrlInput.stringValue = (self.theRadio)[@"radio_url"];
    self.radioCityInput.stringValue = (self.theRadio)[@"radio_city"];
    self.countryInput.stringValue = (self.theRadio)[@"radio_country"];    
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Localize
    self.window.title = NSLocalizedString(@"Add a Favorite", nil);
    self.radioNameLabel.stringValue = NSLocalizedString(@"Radio Name:", @"");
    self.urlLabel.stringValue = NSLocalizedString(@"URL:", @"");
    self.infoLabel.stringValue = NSLocalizedString(@"Info:", @"");
    self.radioUrlLabel.stringValue = NSLocalizedString(@"Radio URL:", @"");
    self.radioCityLabel.stringValue = NSLocalizedString(@"Radio City:", @"");
    self.countryLabel.stringValue = NSLocalizedString(@"Radio Country:", @"");
    [self configureDefaultRadio];
}

- (IBAction)cancelIt:(id)sender
{
    [self.window performClose:nil];
}

- (IBAction)saveIt:(id)sender
{
    (self.theRadio)[@"radio_name"] = self.radioNameInput.stringValue;
    if([(self.theRadio)[@"mp3_url"] isEqualToString:@""])
        (self.theRadio)[@"aac_url"] = self.urlInput.stringValue;
    else
        (self.theRadio)[@"mp3_url"] = self.urlInput.stringValue;
    (self.theRadio)[@"radio_tags"] = self.infoInput.stringValue;
    (self.theRadio)[@"radio_url"] = self.radioUrlInput.stringValue;
    (self.theRadio)[@"radio_city"] = self.radioCityInput.stringValue;
    (self.theRadio)[@"radio_country"] = self.countryInput.stringValue;
    
    [self.delegate saveFavoriteWindowControllerDidSelect:self];
    [self.window performClose:nil];
}
@end
