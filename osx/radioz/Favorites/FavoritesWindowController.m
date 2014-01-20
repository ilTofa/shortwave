//
//  FavoritesWindowController.m
//  radioz
//
//  Created by Giacomo Tufano on 28/11/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "FavoritesWindowController.h"
#import "SDCloudUserDefaults.h"
#import "RadiozAppDelegate.h"

@interface FavoritesWindowController () <NSTableViewDelegate>

@property (strong) NSString *pUUID;

@end

@implementation FavoritesWindowController

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
    self.window.title = NSLocalizedString(@"Favorites", @"");
    self.window.backgroundColor = [NSColor colorWithDeviceRed:240.0/255.0 green:198.0/255.0 blue:150.0/255.0 alpha:1.0];
    self.pUUID = [SDCloudUserDefaults stringForKey:@"pUUID"];
    DLog(@"pUUID: %@", self.pUUID);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:) name:NSControlTextDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainUIisBusy:) name:kMainUIBusy object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainUIisReady:) name:kMainUIReady object:nil];
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
    DLog(@"This is windowDidBecomeKey:");
    [self populateTable];
}

- (void) populateTable
{
//    [self.arrayController.arrangedObjects removeAllObjects];
    PFQuery *query = [PFQuery queryWithClassName:@"Favorite"];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    // We want favorites for current user
    [query whereKey:@"pUUID" equalTo:self.pUUID];
    [query orderByAscending:@"radioName"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            DLog(@"Successfully retrieved %ld scores.", objects.count);
            // Now load the array Controller
            [[self.arrayController mutableArrayValueForKey:@"content"] removeAllObjects];
            for (PFObject *row in objects) {
                [self.arrayController addObject:row];
            }
            [self.theTable reloadData];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)mainUIisBusy:(NSNotification *)notification
{
    DLog(@"Main UI is processing something, disabling Play button.");
    [self.playButton setEnabled:NO];
}

- (void)mainUIisReady:(NSNotification *)notification
{
    DLog(@"Main UI is now ready, re-enabling Play button.");
    [self.playButton setEnabled:YES];
}

- (void)editingDidEnd:(NSNotification *)notification
{
    // Updating changed data on Parse backend
    DLog(@"This is editingDidEnd:");
    for (PFObject *row in self.arrayController.arrangedObjects) {
        DLog(@"Saving %@", row);
        [row saveInBackground];
    }
}

- (IBAction)selectPressed:(id)sender
{
    if(self.theTable.selectedRow != -1)
    {
        PFObject *favoriteToBePlayed = [self.arrayController.arrangedObjects objectAtIndex:self.theTable.selectedRow];
        DLog(@"selectPressed: on Object: %@", favoriteToBePlayed);
        [self.delegate favoritesWindowControllerDidSelect:self withObject:favoriteToBePlayed];
    }
}

- (IBAction)deletePressed:(id)sender
{
    if(self.theTable.selectedRow != -1)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"Are you sure you want to delete the favorite?", nil)];
        [alert setMessageText:NSLocalizedString(@"Error", @"")];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Delete"];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if(self.theTable.selectedRow != -1 && returnCode == NSAlertSecondButtonReturn)
    {
        PFObject *favoriteToBeDeleted = [self.arrayController.arrangedObjects objectAtIndex:self.theTable.selectedRow];
        DLog(@"deletePressed: on Object: %@", favoriteToBeDeleted);
        [favoriteToBeDeleted deleteInBackground];
        [self.arrayController removeObjectAtArrangedObjectIndex:self.theTable.selectedRow];
    }
}

@end
