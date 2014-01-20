//
//  DisplayFavsViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 04/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "DisplayFavsViewController.h"
#import "SDCloudUserDefaults.h"

@interface DisplayFavsViewController ()

@end

@implementation DisplayFavsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithClassName:@"Favorite"];
    self = [super initWithCoder:aDecoder];
    if (self) 
    {
        // The className to query on
        self.className = @"Favorite";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 13;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Favorites", @"");
    self.view.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:198.0/255.0 blue:150.0/255.0 alpha:1.0];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
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

#pragma mark - Parse

 // Override to customize what kind of query to perform on the class. The default is to query for
 // all objects ordered by createdAt descending.
- (PFQuery *)queryForTable 
{
    PFQuery *query = [PFQuery queryWithClassName:self.className];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) 
    {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    // We want favorites for current user
    [query whereKey:@"pUUID" equalTo:[SDCloudUserDefaults stringForKey:@"pUUID"]];
    [query orderByAscending:@"radioName"];
    
    return query;
}


 // Override to customize the look of a cell representing an object. The default is to display
 // a UITableViewCellStyleDefault style cell with the label being the first key in the object. 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object 
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell
    cell.textLabel.text = object[@"radioName"];
    cell.detailTextLabel.text = object[@"info"];
    
    return cell;
}



#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    
    return cell;
}*/

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
        // Delete the row from the data source (and then reload the table)
        [(self.objects)[indexPath.row] deleteInBackgroundWithBlock:^(BOOL succeded, NSError *error) {
            if(!error)
                [self loadObjects];
        }];
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
    if (indexPath.row < [self.objects count])
    {
        // get back to delegate.
        [self.delegate displayFavsViewControllerDidSelect:self withObject:(self.objects)[indexPath.row]];
    } else {
        // This is the pagination cell so let the parent handle it
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}


- (IBAction)cancel:(id)sender 
{
    [self.delegate displayFavsViewControllerDidCancel:self];
}
@end
