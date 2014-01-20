//
//  SaveFavViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 31/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "SaveFavViewController.h"

@interface SaveFavViewController ()

@end

@implementation SaveFavViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)configureView
{
    self.radioNameInput.text = (self.theRadio)[@"radio_name"];
    if([(self.theRadio)[@"mp3_url"] isEqualToString:@""])
        self.urlInput.text = (self.theRadio)[@"aac_url"];
    else
        self.urlInput.text = (self.theRadio)[@"mp3_url"];
    self.infoInput.text = (self.theRadio)[@"radio_tags"];
    self.radioUrlInput.text = (self.theRadio)[@"radio_url"];
    self.radioCityInput.text = (self.theRadio)[@"radio_city"];
    self.radioCountryInput.text = (self.theRadio)[@"radio_country"];
        
    // set keyboard on iPhone
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        [self.radioNameInput becomeFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
    // Localize
    self.radioNameLabel.text = NSLocalizedString(@"Radio Name:", @"");
    self.urlLabel.text = NSLocalizedString(@"URL:", @"");
    self.infoLabel.text = NSLocalizedString(@"Info:", @"");
    self.radioUrlLabel.text = NSLocalizedString(@"Radio URL:", @"");
    self.radioCityLabel.text = NSLocalizedString(@"Radio City:", @"");
    self.radioCountryLabel.text = NSLocalizedString(@"Radio Country:", @"");
}

- (void)viewDidUnload
{
    [self setRadioNameInput:nil];
    [self setUrlInput:nil];
    [self setInfoInput:nil];
    [self setRadioUrlInput:nil];
    [self setRadioCityInput:nil];
    [self setRadioCountryInput:nil];
    [self setRadioNameLabel:nil];
    [self setUrlLabel:nil];
    [self setInfoLabel:nil];
    [self setRadioUrlLabel:nil];
    [self setRadioCityLabel:nil];
    [self setRadioCountryLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}


- (IBAction)cancel:(id)sender
{
    [self.delegate saveFavViewControllerDidCancel:self];
}

- (IBAction)done:(id)sender
{
    (self.theRadio)[@"radio_name"] = self.radioNameInput.text;
    if([(self.theRadio)[@"mp3_url"] isEqualToString:@""])
        (self.theRadio)[@"aac_url"] = self.urlInput.text;
    else
        (self.theRadio)[@"mp3_url"] = self.urlInput.text;
    (self.theRadio)[@"radio_tags"] = self.infoInput.text;
    (self.theRadio)[@"radio_url"] = self.radioUrlInput.text;
    (self.theRadio)[@"radio_city"] = self.radioCityInput.text;
    (self.theRadio)[@"radio_country"] = self.radioCountryInput.text;

    [self.delegate saveFavViewControllerDidSelect:self];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // only on iPad
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if ((textField == self.radioNameInput) || (textField == self.urlInput) || (textField == self.infoInput))
        {
            [textField resignFirstResponder];
        }
    }
    return YES;
}

@end
