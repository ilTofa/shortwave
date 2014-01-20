//
//  SongsViewController.m
//  RP HD
//
//  Created by Giacomo Tufano on 03/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "SongsViewController.h"
#import "RadiozAppDelegate.h"
#import "CoreDataController.h"

#import <QuartzCore/QuartzCore.h>
#import <MessageUI/MessageUI.h>
#import <Twitter/Twitter.h>
#import "Song.h"
#import "PiwikTracker.h"

@interface SongsViewController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@end

@implementation SongsViewController

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
        
        // we can now allow for editing
        self.editButton.enabled = YES;
        
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

- (void)setupTheToolbar
{
    UIBarButtonItem *theCancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(userDone:)];
    UIBarButtonItem *theSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *theEdit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(self.tableView.isEditing) ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit target:self action:@selector(editTable:)];
    NSArray *theButtons = @[theCancel, theSpace, theEdit];
    [self.theToolbar setItems:theButtons animated:NO];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
 
    // setup
    [self setupTheToolbar];
    [self hideSearchBar];
    RadiozAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    self.managedObjectContext = appDelegate.coreDataController.mainThreadContext;    
     // Notifications to be honored during controller lifecycle
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFetchedResults:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:appDelegate.coreDataController.psc];
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFetchedResults:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:appDelegate.coreDataController.psc];
    self.searchString = @"";
    self.searchScope = 0;
    [self setupFetchExecAndReload];
}

- (void)viewDidUnload {
    [self setEditButton:nil];
    [self setTheToolbar:nil];
    [self setSearchBar:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Song *song = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // Probably a custom cell should be used (with an image for the cover and the date added)
    cell.textLabel.text = song.title;
    cell.detailTextLabel.text = song.artist;
    [cell.imageView.layer setCornerRadius:5.0f];
    [cell.imageView.layer setMasksToBounds:YES];
    [cell.imageView setImage:[UIImage imageWithData:song.cover]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    DLog(@"shouldAutorotateToInterfaceOrientation called for mainController");
    if((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    else
        return NO;
}

#pragma mark - Action buttons

- (IBAction)userDone:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)editTable:(id)sender
{
    DLog(@"%@ editing on song table", (self.tableView.isEditing) ? @"Stopping" : @"Starting");
    [self.tableView setEditing:!(self.tableView.isEditing) animated:YES];
    [self setupTheToolbar];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.fetchedResultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
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


// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check what the user wants to do and do it. :)
    Song *selectedSong = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    self.theSelectedArtist = selectedSong.artist;
    self.theSelectedTitle = selectedSong.title;
    self.theSelectedCover = selectedSong.cover;
    NSString *actionTitle = [NSString stringWithFormat:@"%@ - %@", self.theSelectedArtist, self.theSelectedTitle];
    UIActionSheet *theChoices;
    theChoices = [[UIActionSheet alloc] initWithTitle:actionTitle delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Send by e-mail", @""), NSLocalizedString(@"Tweet it", @""), NSLocalizedString(@"iTunes Store", @""), nil];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [theChoices showFromRect:cell.frame inView:self.view animated:YES];
    }
    else
        [theChoices showInView:self.view];
}

#pragma mark -
#pragma mark UIActionSheetDelegate method: where the choice is made. :)

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *action;
    switch (buttonIndex) {
        case 3:
            action = @"cancel";
            break;
        case 0:
            action = @"send an e-mail";
            if([MFMailComposeViewController canSendMail])
                [self sendSongByEmail];
            else
            {
                UIAlertView *alertBox = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"Sorry, cannot send email from this device. Please check configuration.", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertBox show];
            }
            break;
        case 1:
            action = @"twit";
            if([TWTweetComposeViewController canSendTweet])
                [self sendSongByTweet];
            else
            {
                UIAlertView *alertBox = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"Sorry, cannot send a tweet now from this device. Please check network and/or configuration.", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alertBox show];
            }
            break;
        case 2:
            action = @"go to the store";
            [self gotoStore];
            break;
        default:
            action = @"do something impossible";
            break;
    }
    DLog(@"User wants to %@", action);
}

-(void) sendSongByTweet
{
    TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    [tweetViewController setInitialText:[NSString stringWithFormat:@"%@ - %@\n", self.theSelectedArtist, self.theSelectedTitle]];
    [tweetViewController addImage:[UIImage imageWithData:self.theSelectedCover]];
    [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
        switch (result) {
            case TWTweetComposeViewControllerResultCancelled:
                DLog(@"Tweet cancelled.");
                [[PiwikTracker sharedInstance] sendEventWithCategory:@"share" action:@"tweetCancelled" label:@""];
                break;
            case TWTweetComposeViewControllerResultDone:
                DLog(@"Tweet done.");
                [[PiwikTracker sharedInstance] sendEventWithCategory:@"share" action:@"tweetSent" label:@""];
                break;
            default:
                break;
        }        
        [self dismissModalViewControllerAnimated:YES];
    }];
    
    [self presentModalViewController:tweetViewController animated:YES];
}

-(void) sendSongByEmail
{
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setSubject:NSLocalizedString(@"Song saved in RadioZ", @"")];
    [controller setMessageBody:[NSString stringWithFormat:@"%@ - %@\n", self.theSelectedArtist, self.theSelectedTitle] isHTML:NO];
    [controller addAttachmentData:self.theSelectedCover mimeType:@"image/png" fileName:@"Cover.png"];
    if (controller)
        [self presentModalViewController:controller animated:YES];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        DLog(@"e-mail Sent!");
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"share" action:@"mailSent" label:@""];
    }
    else
    {
        [[PiwikTracker sharedInstance] sendEventWithCategory:@"share" action:@"mailCancelled" label:@""];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark iTunes Store management

-(void)gotoStore
{
    DLog(@"trying to get current locale setting");
    // For easy testing with other locales
//    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSString *storeCode = [locale objectForKey:NSLocaleCountryCode];
    DLog(@"Device is configured for %@", storeCode);
    // Now search for the song and quit.
    [self sendUserToStoreFor:[NSString stringWithFormat:@"%@ %@", self.theSelectedArtist, self.theSelectedTitle] onStoreCode:storeCode];
    [self userDone:nil];
}

-(NSString *)generateAffiliateLinkFor:(NSString *)iTunesUrl andStoreCode:(NSString *)storeCode
{
    static NSString *PHGAffiliateCode = @"11l7nM";
    NSString *returnUrl;
    NSRange rangeForQuestionMark = [iTunesUrl rangeOfString:@"?" options:NSCaseInsensitiveSearch];
    if ([storeCode caseInsensitiveCompare:@"gb"] == NSOrderedSame || [storeCode caseInsensitiveCompare:@"uk"] == NSOrderedSame)
    {
        // Generate a Tradedoubler link
        returnUrl = [NSString stringWithFormat:@"http://clkuk.tradedoubler.com/click?p=23708&a=2141801&url=%@%@partnerId=2003", iTunesUrl, (rangeForQuestionMark.location != NSNotFound) ? @"&" : @"?"];
    }
    else if ([storeCode caseInsensitiveCompare:@"it"] == NSOrderedSame)
    {
        // Generate a Tradedoubler link
        returnUrl = [NSString stringWithFormat:@"http://clkuk.tradedoubler.com/click?p=24373&a=2165395&url=%@%@partnerId=2003", iTunesUrl, (rangeForQuestionMark.location != NSNotFound) ? @"&" : @"?"];
    }
    else if ([storeCode caseInsensitiveCompare:@"de"] == NSOrderedSame)
    {
        // Generate a Tradedoubler link
        returnUrl = [NSString stringWithFormat:@"http://clkuk.tradedoubler.com/click?p=23761&a=2141800&url=%@%@partnerId=2003", iTunesUrl, (rangeForQuestionMark.location != NSNotFound) ? @"&" : @"?"];
    }
    else if ([storeCode caseInsensitiveCompare:@"fr"] == NSOrderedSame)
    {
        // Generate a Tradedoubler link
        returnUrl = [NSString stringWithFormat:@"http://clkuk.tradedoubler.com/click?p=23753&a=2141803&url=%@%@partnerId=2003", iTunesUrl, (rangeForQuestionMark.location != NSNotFound) ? @"&" : @"?"];
    }
    else
    {
        // Send any other store through PHG
        returnUrl = [NSString stringWithFormat:@"%@%@at=%@", iTunesUrl, (rangeForQuestionMark.location != NSNotFound) ? @"&" : @"?", PHGAffiliateCode];
    }
    returnUrl = [returnUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    DLog(@"Affiliate link is: <%@>", returnUrl);
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"share" action:@"iTunesStore" label:storeCode];
    return returnUrl;
}

-(void)sendUserToStoreFor:(NSString *)searchString onStoreCode:(NSString *)storeCode
{
    NSString *searchUrl = [[[NSString stringWithFormat:@"http://itunes.apple.com/search?term=%@&country=%@&media=music&limit=1", searchString, storeCode] stringByReplacingOccurrencesOfString:@" " withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    DLog(@"Store URL is: %@", searchUrl);
    NSMutableURLRequest *req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:searchUrl]];
    [req setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [NSURLConnection sendAsynchronousRequest:req queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *res, NSData *data, NSError *err)
     {
         DLog(@" %@ ", (data) ? @"successfully." : @"with errors.");
         if(data)
         {
             // Get JSON data
             NSError *err;
             NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&err];
             if(!jsonObject)
             {
                 NSLog(@"Error reading JSON data: %@", [err description]);
                 return;
             }
             else
             {
                 NSArray *songsData = jsonObject[@"results"];
                 if(songsData == nil || [songsData count] ==0)
                 {
                     NSLog(@"Error in JSON dictionary: %@", jsonObject);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"The song seems to not exist on iTunes Store. You could retry after a while.", @"") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     });
                     return;
                 }
                 NSDictionary *songData = songsData[0];
                 if(!songData)
                 {
                     NSLog(@"Error in JSON first level array: %@", songsData);
                     return;
                 }
                 DLog(@"Song data\n%@", songData);
                 NSString *songURL = songData[@"collectionViewUrl"];
                 if(!songURL)
                 {
                     songURL = songData[@"trackViewUrl"];
                     if(!songURL)
                     {
                         NSLog(@"Error in song dictionary: %@", songData);
                         return;
                     }
                 }
                 DLog(@"The requested song URL is: <%@>.", songURL);
                 NSString *affiliateLinkUrl = [self generateAffiliateLinkFor:songURL andStoreCode:storeCode];
                 DLog(@"Affiliate URL for the same is: <%@>. Calling it.", affiliateLinkUrl);
                 self.iTunesURL = [NSURL URLWithString:affiliateLinkUrl];
                 // Skip redirection engine for direct URLs
                 dispatch_async(dispatch_get_main_queue(), ^{
                     if([self.iTunesURL.host hasSuffix:@"itunes.apple.com"])
                         [[UIApplication sharedApplication] openURL:self.iTunesURL];
                     else
                         [self openReferralURL:self.iTunesURL];
                 });
             }
         }
     }];
}

// That's Apple code from QA1629

// Process a LinkShare/TradeDoubler/DGM URL to something iPhone can handle
- (void)openReferralURL:(NSURL *)referralURL
{
    NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:referralURL] delegate:self startImmediately:YES];
    if(!con)
        NSLog(@"Error in connecting to %@", referralURL);
}

// Save the most recent URL in case multiple redirects occur
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    self.iTunesURL = [response URL];
    if( [self.iTunesURL.host hasSuffix:@"itunes.apple.com"])
    {
        [connection cancel];
        [self connectionDidFinishLoading:connection];
        return nil;
    }
    else
    {
        DLog(@"Got redirected to <%@>", self.iTunesURL);
        return request;
    }
}

// No more redirects; use the last URL saved
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[UIApplication sharedApplication] openURL:self.iTunesURL];
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
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

#pragma mark -
#pragma mark Search and search delegate

- (void)setupFetchExecAndReload
{
    // Set up the fetched results controller
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Song"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *dateAddedSortDesc = [[NSSortDescriptor alloc] initWithKey:@"dateadded" ascending:NO];
    NSArray *sortDescriptors = @[dateAddedSortDesc];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSString *queryString;
    switch (self.searchScope) {
        case 0:
            queryString = [NSString stringWithFormat:@"artist like[c] \"*%@*\"", self.searchString];
            break;
        case 1:
            queryString = [NSString stringWithFormat:@"title like[c] \"*%@*\"", self.searchString];
            break;
            ;
        default:
            queryString = nil;
            break;
    }
    if(queryString)
    {
        DLog(@"Fetching again. Query string is: '%@'", queryString);
		NSPredicate *predicate = [NSPredicate predicateWithFormat:queryString];
		[fetchRequest setPredicate:predicate];
    }
    // Edit the section name key path and cache name if appropriate,
    // nil for section name key path means "no sections"
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
}

- (void) hideSearchBar
{
    self.tableView.contentOffset = CGPointMake( 0, self.searchBar.frame.size.height );
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    DLog(@"Search scope changed to %d", selectedScope);
    self.searchScope = selectedScope;
    [self setupFetchExecAndReload];
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    DLog(@"Cancel clicked");
    [searchBar resignFirstResponder];
    [self hideSearchBar];
    searchBar.text = self.searchString = @"";
    [self setupFetchExecAndReload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    DLog(@"Search should start for '%@'", searchBar.text);
    [searchBar resignFirstResponder];
    self.searchString = searchBar.text;
    [self setupFetchExecAndReload];
}

@end
