//
//  RadioChooserViewController.m
//  radioz
//
//  Created by Giacomo Tufano on 22/05/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadioChooserViewController.h"

#import "RadiozAppDelegate.h"
#import "CoreDataController.h"
#import "RadioListCell.h"
#import "Radio.h"
#import "SDCloudUserDefaults.h"
#import "PiwikTracker.h"
#import <Parse/Parse.h>

@interface RadioChooserViewController ()

@end

@implementation RadioChooserViewController

#pragma mark -
#pragma mark Radio Errors

-(void)saveRadioError:(NSString *)theError forUrl:(NSString *)Url
{
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"error" action:@"radio" label:@""];
    // Save favorite to Parse.
    PFObject *err = [PFObject objectWithClassName:@"RadioError"];
    err[@"pUUID"] = [SDCloudUserDefaults stringForKey:@"pUUID"];
    if(Url)
        err[@"currentRadioRedirectorURL"] = Url;
    err[@"error"] = theError;
    [err saveEventually];
}

#pragma mark -
#pragma mark View lifecycle

// because the app delegate now loads the NSPersistentStore into the NSPersistentStoreCoordinator asynchronously
// we will see the NSManagedObjectContext set up before any persistent stores are registered
// we will need to fetch again after the persistent store is loaded
//
- (void)reloadFetchedResults:(NSNotification *)note
{
    DLog(@"this is reloadFetchedResults: that got a notification.");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError *error = nil;
        
        if (self.fetchedResultsController)
        {
            if (![[self fetchedResultsController] performFetch:&error])
            {
                /*
                 Replace this implementation with code to handle the error appropriately.
                 
                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                 */
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            } else {
                [self.tableView reloadData];
            }
        }
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadPreviousSearchKeys];
    // Set some sane defaults
    RadiozAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.coreDataController.mainThreadContext;
    // Localize search bar buttons and title
    self.searchBar.scopeButtonTitles = @[NSLocalizedString(@"Any", @""), NSLocalizedString(@"Name", @""), NSLocalizedString(@"Country", @""), NSLocalizedString(@"Tag", @"")];
    self.title = NSLocalizedString(@"Radio List", @"");
    // Notifications to be honored during controller lifecycle
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFetchedResults:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:appDelegate.coreDataController.psc];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFetchedResults:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:appDelegate.coreDataController.psc];
    [self setupFetchExecAndReload];
}

- (void)viewDidUnload
{
    [self setSearchBar:nil];
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown || interfaceOrientation == UIInterfaceOrientationPortrait);
    } else {
        return YES;
    }
}

-(void)loadPreviousSearchKeys
{
    DLog(@"Loading previous search keys.");
    self.searchText = [[NSUserDefaults standardUserDefaults] stringForKey:@"searchText"];
    if(!self.searchText)
        self.searchText = @"";
    self.searchKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"searchKey"];
    if(!self.searchKey)
        self.searchKey = @"searchkey";
    self.searchScope = [[NSUserDefaults standardUserDefaults] integerForKey:@"searchScope"];
    self.searchBar.text = self.searchText;
}

-(void)saveSearchKeys
{
    DLog(@"Saving search keys for later use.");
    [[NSUserDefaults standardUserDefaults] setObject:self.searchText forKey:@"searchText"];
    [[NSUserDefaults standardUserDefaults] setObject:self.searchKey forKey:@"searchKey"];
    [[NSUserDefaults standardUserDefaults] setInteger:self.searchScope forKey:@"searchScope"];    
}

#pragma mark -
#pragma mark Search and search delegate

- (void)setupFetchExecAndReload
{
    // Set up the fetched results controller
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Radio" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize:25];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *dateAddedSortDesc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = @[dateAddedSortDesc];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSString *queryString = nil;
    if(![self.searchText isEqualToString:@""])
    {
        // Complex NSPredicate needed to match any word in the search string
        DLog(@"Fetching again. Query string is: '%@' in %@", self.searchText, self.searchKey);
        NSArray *terms = [self.searchText componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for(NSString *term in terms)
        {
            if([term length] == 0)
                continue;
            if(queryString == nil)
                queryString = [NSString stringWithFormat:@"%@ contains[cd] \"%@\"", self.searchKey, term];
            else
                queryString = [queryString stringByAppendingFormat:@" AND %@ contains[cd] \"%@\"", self.searchKey, term];
        }
    }
    else
        queryString = [NSString stringWithFormat:@"%@  like[c] \"*\"", self.searchKey];
    DLog(@"Fetching again. Query string is: '%@'", queryString);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:queryString];
    [fetchRequest setPredicate:predicate];

    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    DLog(@"Fetch setup to: %@", self.fetchedResultsController);
    NSError *error = nil;
    if (self.fetchedResultsController != nil) {
        if (![[self fetchedResultsController] performFetch:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        else
            [self.tableView reloadData];
    }
    [self saveSearchKeys];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [searchBar setShowsCancelButton:YES animated:YES];
    self.tableView.allowsSelection = NO;
    self.tableView.scrollEnabled = NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DLog(@"Cancel clicked");
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
    searchBar.text = self.searchText = @"";
    [self setupFetchExecAndReload];
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    self.searchScope = selectedScope;
    DLog(@"selected button %d", self.searchScope);
    switch (self.searchScope)
    {
        case 0:
            self.searchKey = @"searchkey";
            break;
        case 1:
            self.searchKey = @"name";
            break;
        case 2:
            self.searchKey = @"country";
            break;
        case 3:
            self.searchKey = @"tags";
            break;
        default:
            self.searchKey = @"searchkey";
            break;
    }
    [self setupFetchExecAndReload];
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    DLog(@"Search should start for '%@'", searchBar.text);
    [searchBar resignFirstResponder];
    self.searchText = searchBar.text;
    self.tableView.allowsSelection = YES;
    self.tableView.scrollEnabled = YES;
    // Perform search... :)
    DLog(@"Now searching %@ (scope %@)", self.searchText, self.searchKey);
    [self setupFetchExecAndReload];
}

#pragma mark -
#pragma mark Fetched results controller delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    DLog(@"this is controllerWillChangeContent");
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    DLog(@"This is controller didChangeObject:atIndexPath:forChangeType:newIndexPath:");
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(RadioListCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    DLog(@"This is controllerDidChangeContent:");
    [self.tableView endUpdates];
}

#pragma mark -
#pragma mark - Table view data source

- (void)configureCell:(RadioListCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Radio *radio = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.radioName.text = radio.name;
    cell.radioSite.text = [NSString stringWithFormat:@"%@, %@", radio.city, radio.country];
    cell.radioTags.text = radio.tags;
    cell.radioMP3.hidden = [radio.mp3_url isEqualToString:@""];
    cell.radioAAC.hidden = [radio.aac_url isEqualToString:@""];
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object. 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    static NSString *CellIdentifier = @"RadioCell";
    
    RadioListCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[RadioListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.fetchedResultsController fetchedObjects] count];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disable user interaction to avoid double clicks.
    tableView.userInteractionEnabled = NO;
    // We have a radio, now get the best streaming URL we can get.
    Radio *selectedRadio =  [[self fetchedResultsController] objectAtIndexPath:indexPath];
    // Let's see if AAC or MP3
    NSString *requestedURL;
    if([selectedRadio.aac_url isEqualToString:@""])
        requestedURL = selectedRadio.mp3_url;
    else
        requestedURL = selectedRadio.aac_url;
    DLog(@"User clicked to load <%@>", requestedURL);
    // Now search for audio redirector type of files
    NSArray *values = @[@".m3u", @".pls", @".wax", @".ram", @".pls", @".m4u"];
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@" %@ ENDSWITH[cd] SELF ", requestedURL];
    NSArray * searchResults = [values filteredArrayUsingPredicate:predicate];
    // if an audio redirector is found...
    if([searchResults count] > 0)
    {
        DLog(@"Found an audio redirector of type %@", searchResults[0]);
        // Now loading the redirector to find the "right" URL
        DLog(@"Loading audio redirector of type %@ from <%@>.", searchResults[0], requestedURL);
        NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:requestedURL]];
        [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
         {
             if(data && [(NSHTTPURLResponse *)res statusCode] == 200)
             {
                 NSString *redirectorData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                 DLog(@"Data from redirector are:\n<%@>", redirectorData);
                 // Now get the URLs
                 NSError *error = NULL;
                 NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:&error];
                 NSTextCheckingResult *result = [detector firstMatchInString:redirectorData options:0 range:NSMakeRange(0, [redirectorData length])];
                 if(result && result.range.location != NSNotFound)
                 {
                     DLog(@"Found URL: %@", result.URL);
                     self.theSelectedStreamURL = [result.URL absoluteString];
                     // call the delegate on main thread
                     dispatch_async(dispatch_get_main_queue(), ^{
                         DLog(@"calling delegate");
                         [self.delegate radioChooserViewControllerDidSelect:self withObject:selectedRadio];
                     });
                 }
                 else
                 {
                     NSString *temp = NSLocalizedString(@"URL not found in redirector.", @"");
                     NSLog(@"%@", temp);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self saveRadioError:temp forUrl:[res.URL absoluteString]];
                         tableView.userInteractionEnabled = YES;
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:temp delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles: nil];
                         [alert show];
                     });
                 }
             }
             else
             {
                 NSString *temp;
                 if([(NSHTTPURLResponse *)res statusCode] != 200)
                     temp = [NSString stringWithFormat:NSLocalizedString(@"HTTP error loading redirector: %d", @""), [(NSHTTPURLResponse *)res statusCode]];
                 else
                     temp = [NSString stringWithFormat:NSLocalizedString(@"Error loading redirector: %@", @""), [err localizedDescription]];
                 NSLog(@"%@", temp);
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self saveRadioError:temp forUrl:[res.URL absoluteString]];
                     tableView.userInteractionEnabled = YES;
                     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"") message:temp delegate:nil cancelButtonTitle:NSLocalizedString(@"Cancel", @"") otherButtonTitles: nil];
                     [alert show];
                 });
             }
         }];
    }
    else
        tableView.userInteractionEnabled = YES;
}

- (IBAction)cancel:(id)sender
{
    [self.delegate radioChooserViewControllerDidCancel:self];
}

@end