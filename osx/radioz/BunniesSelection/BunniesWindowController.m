//
//  BunniesWindowController.m
//  radioz
//
//  Created by Giacomo Tufano on 05/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "BunniesWindowController.h"

#import "SaveBunnyWindowController.h"
#import "SDCloudUserDefaults.h"

@interface BunniesWindowController () <SaveBunnyWindowControllerDelegate>

@property (strong) SaveBunnyWindowController *addBunnyController;

@end

@implementation BunniesWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)loadArray
{
    // Load array of bunnies from iCloud/defaults
    NSData *dataRepresentingSavedArray = [SDCloudUserDefaults objectForKey:@"bunniesArray"];
    if(dataRepresentingSavedArray != nil)
    {
        NSArray *aTemporaryArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
        if (aTemporaryArray != nil)
            self.theBunniesArray = [[NSMutableArray alloc] initWithArray:aTemporaryArray];
    }
    else    //(there is no array in bunniesArray or data is invalid
    {
        DLog(@"Initing bunniesArray");
        self.theBunniesArray = [[NSMutableArray alloc] init];
        [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.theBunniesArray] forKey:@"bunniesArray"];
    }
    // Load the arrayController.
    [[self.arrayController mutableArrayValueForKey:@"content"] removeAllObjects];
    for (Bunny *bunny in self.theBunniesArray) {
        DLog(@"adding %@ to arrayController.", bunny);
        [self.arrayController addObject:bunny];
    }
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    DLog(@"[BunniesViewController windowDidLoad] called.");
    self.window.title = NSLocalizedString(@"Bunnies", @"");
    self.window.backgroundColor = [NSColor colorWithDeviceRed:240.0/255.0 green:198.0/255.0 blue:150.0/255.0 alpha:1.0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEnd:) name:NSControlTextDidEndEditingNotification object:nil];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    [self loadArray];
}

- (void)editingDidEnd:(NSNotification *)notification
{
    // Updating changed data on Parse backend
    DLog(@"This is editingDidEnd: saving new bunnies array");
    self.theBunniesArray = [[NSMutableArray alloc] initWithArray:self.arrayController.arrangedObjects];
    [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.theBunniesArray] forKey:@"bunniesArray"];
}

- (IBAction)playPressed:(id)sender
{
    if(self.theTable.selectedRow != -1)
    {
        Bunny *theSelectedBunny = [self.arrayController.arrangedObjects objectAtIndex:self.theTable.selectedRow];
        DLog(@"playPressed: on bunny: %@", theSelectedBunny);
        [self.delegate bunniesWindowControllerDidSelect:self withObject:theSelectedBunny];
        [self.window performClose:self];
    }
}

- (IBAction)addBunny:(id)sender
{
    if(!self.addBunnyController)
    {
        self.addBunnyController = [[SaveBunnyWindowController alloc] initWithWindowNibName:@"SaveBunnyWindowController"];
        self.addBunnyController.delegate = self;
    }
    [self.addBunnyController showWindow:self];
}

- (IBAction)deleteBunny:(id)sender
{
    if(self.theTable.selectedRow != -1)
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:NSLocalizedString(@"Are you sure you want to delete the bunny?", nil)];
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
        Bunny __unused *theSelectedBunny = [self.arrayController.arrangedObjects objectAtIndex:self.theTable.selectedRow];
        DLog(@"deleteBunny: on bunny: %@, row %ld", theSelectedBunny, self.theTable.selectedRow);
        [self.arrayController removeObjectAtArrangedObjectIndex:self.theTable.selectedRow];
        self.theBunniesArray = [[NSMutableArray alloc] initWithArray:self.arrayController.arrangedObjects];
        [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.theBunniesArray] forKey:@"bunniesArray"];
    }
}

- (void)saveBunnyWindowControllerDidSave:(SaveBunnyWindowController *)controller
{
    // Saved a new bunny, reload table...
    [self loadArray];
}

@end
