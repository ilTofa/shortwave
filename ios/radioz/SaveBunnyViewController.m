//
//  SaveBunnyViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 15/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "SaveBunnyViewController.h"
#import "SDCloudUserDefaults.h"
#import "Bunny.h"

@interface SaveBunnyViewController ()

@end

@implementation SaveBunnyViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Localization
    self.nameLabel.text = NSLocalizedString(@"Bunny Name", @"");
    self.name.placeholder = NSLocalizedString(@"A name for your bunny", @"");
    self.apiLabel.text = NSLocalizedString(@"API Key", @"");
    self.key.placeholder = NSLocalizedString(@"API KEY or Install-ID (from karotz store bunny page)", @"");
    [self.karotzIdButton setTitle:NSLocalizedString(@"Get Karotz Install-ID", @"") forState:UIControlStateNormal];
    [self.karotzIdButton setTitle:NSLocalizedString(@"Get Karotz Install-ID", @"") forState:UIControlStateHighlighted];
    [self.karotzIdButton setTitle:NSLocalizedString(@"Get Karotz Install-ID", @"") forState:UIControlStateDisabled];
}

- (void)viewDidUnload
{
    [self setName:nil];
    [self setKey:nil];
    [self setBunnyType:nil];
    [self setNameLabel:nil];
    [self setApiLabel:nil];
    [self setKarotzIdButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)save:(id)sender 
{
    NSMutableArray *theBunniesArray;
    // Load array of bunnies from iCloud/defaults
    NSData *dataRepresentingSavedArray = [SDCloudUserDefaults objectForKey:@"bunniesArray"];
    if(dataRepresentingSavedArray != nil)
    {
        NSArray *aTemporaryArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
        if (aTemporaryArray != nil)
            theBunniesArray = [[NSMutableArray alloc] initWithArray:aTemporaryArray];
        else
            theBunniesArray = [[NSMutableArray alloc] init];
    }
    else
        theBunniesArray = [[NSMutableArray alloc] init];
    DLog(@"Current Bunny Array: %@", theBunniesArray);
    for (Bunny *aBunny in theBunniesArray) {
        DLog(@"%@", aBunny);
    }
    // Now add the value
    Bunny *theBunny = [[Bunny alloc] initWithName:self.name.text key:self.key.text asKarotz:(self.bunnyType.selectedSegmentIndex == 0)];
    DLog(@"theBunny: %@", theBunny);
    [theBunniesArray addObject:theBunny];
    // Save data as an NSData archive
    [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:theBunniesArray] forKey:@"bunniesArray"];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)getKarotzId:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.karotz.com/appz/app?id=3740"]];
}
@end
