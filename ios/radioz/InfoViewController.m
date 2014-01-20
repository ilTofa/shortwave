//
//  InfoViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 28/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "InfoViewController.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        if([UIScreen mainScreen].bounds.size.height == 568.0f)
            self.backgroundImage.image = [UIImage imageNamed:@"Default-568h"];
        else
            self.backgroundImage.image = [UIImage imageNamed:@"Default"];
    }
    self.versionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"version %@ (%@)", @""), [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"], [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"]];
    self.textLabel.text = NSLocalizedString(@"InfoText", @"");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissDialog:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)viewDidUnload {
    [self setVersionLabel:nil];
    [self setBackgroundImage:nil];
    [self setTextLabel:nil];
    [super viewDidUnload];
}
@end
