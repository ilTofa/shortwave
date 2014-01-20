//
//  BunniesViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 15/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "BunniesViewController.h"
#import "Bunny.h"

@interface BunniesViewController ()

@end

@implementation BunniesViewController

-(void)loadArray
{
    // Load array of bunnies from iCloud/defaults
    NSData *dataRepresentingSavedArray = [SDCloudUserDefaults objectForKey:@"bunniesArray"];
    if(dataRepresentingSavedArray != nil)
    {
        NSArray *aTemporaryArray = [NSKeyedUnarchiver unarchiveObjectWithData:dataRepresentingSavedArray];
        if (aTemporaryArray != nil)
        {
            self.theBunniesArray = [[NSMutableArray alloc] initWithArray:aTemporaryArray];
            return;
        }
    }
    // else (there is no array in bunniesArray or data is invalid
    DLog(@"Initing bunniesArray");
    self.theBunniesArray = [[NSMutableArray alloc] init];
    [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.theBunniesArray] forKey:@"bunniesArray"];
}

-(IBAction)cancel:(id)sender
{
    [self.delegate bunniesViewControllerDidCancel:self];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    DLog(@"[BunniesViewController initWithStyle:] called.");
    self = [super initWithStyle:style];
    if (self) 
    {
        [self loadArray];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    DLog(@"[BunniesViewController viewDidLoad] called.");
    self.title = NSLocalizedString(@"Bunnies", @"");
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    NSArray *leftButtons = @[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)], 
                            self.editButtonItem];
    self.navigationItem.leftBarButtonItems = leftButtons;
    [self.stopButton setTitle:NSLocalizedString(@"Stop Play", @"") forState:UIControlStateNormal];
    [self.stopButton setTitle:NSLocalizedString(@"Stop Play", @"") forState:UIControlStateHighlighted];
    [self.stopButton setTitle:NSLocalizedString(@"Stop Play", @"") forState:UIControlStateDisabled];
    self.stopButton.enabled = YES;
    [self loadArray];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    DLog(@"[BunniesViewController viewDidAppear:] called.");    
    [self loadArray];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [self setStopButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.theBunniesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Bunny *theCurrentBunny = (self.theBunniesArray)[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", theCurrentBunny.name, [theCurrentBunny.isKarotz boolValue] ? @"Karotz" : @"Nabaztag"];
    cell.detailTextLabel.text = theCurrentBunny.key;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) 
    {
        [self.theBunniesArray removeObjectAtIndex:indexPath.row];
        [SDCloudUserDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:self.theBunniesArray] forKey:@"bunniesArray"];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Bunny *theCurrentBunny = (self.theBunniesArray)[indexPath.row];
    [self.delegate bunniesViewControllerDidSelect:self withObject:theCurrentBunny];
}

#pragma mark - Add Bunnies

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender 
{
    DLog(@"prepareForSegue called for %@", [segue identifier]);
    if ([[segue identifier] isEqualToString:@"AddBunny"])
    {
//        UINavigationController *navigationController = segue.destinationViewController;
//        SaveFavViewController *saveController = [[navigationController viewControllers] objectAtIndex:0];
//        saveController.delegate = self;
//        saveController.radioName = self.stationInfo.text;
//        saveController.url = self.currentRadioRedirectorURL;
//        saveController.info = self.genreInfo.text;
//        // segue is a popover, we have to explicitly call initialization routine and save the popover
//        self.popSegue = (UIStoryboardPopoverSegue*)segue;
//        [saveController configureView];
    }
}

- (IBAction)stopBunnies:(id)sender
{
    self.stopButton.enabled = NO;
    [self.delegate bunniesViewControllerWantsBunnyPlayStopped:self];
}
@end
