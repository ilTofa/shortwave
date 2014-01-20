//
//  SaveBunnyWindowController.m
//  radioz
//
//  Created by Giacomo Tufano on 05/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "SaveBunnyWindowController.h"

#import "Bunny.h"
#import "SDCloudUserDefaults.h"

@interface SaveBunnyWindowController ()

@end

@implementation SaveBunnyWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Localization
    self.window.title = NSLocalizedString(@"Add a bunny", nil);
    self.window.backgroundColor = [NSColor colorWithDeviceRed:240.0/255.0 green:198.0/255.0 blue:150.0/255.0 alpha:1.0];
    self.nameLabel.stringValue = NSLocalizedString(@"Bunny Name", @"");
    [self.name.cell setPlaceholderString:NSLocalizedString(@"A name for your bunny", @"")];
    [self.key.cell setPlaceholderString:NSLocalizedString(@"API KEY or Install-ID (from karotz store bunny page)", @"")];
    self.apiLabel.stringValue = NSLocalizedString(@"API Key", @"");
}

- (IBAction)save:(id)sender
{
    if([self.name.stringValue isEqualToString:@""] || [self.key.stringValue isEqualToString:@""])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"Please enter a name and a key", nil)];
        [alert setMessageText:NSLocalizedString(@"Error", @"")];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
        return;
    }
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
    // Now add the value
    Bunny *theBunny = [[Bunny alloc] initWithName:self.name.stringValue key:self.key.stringValue asKarotz:(self.bunnyType.selectedSegment == 0)];
    DLog(@"Adding bunny: %@", theBunny);
    [theBunniesArray addObject:theBunny];
    // Save data as an NSData archive
    [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:theBunniesArray] forKey:@"bunniesArray"];
    [self.window performClose:nil];
    [self.delegate saveBunnyWindowControllerDidSave:self];
}
@end
