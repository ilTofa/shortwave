//
//  radioListWindowController.m
//  radioz
//
//  Created by Giacomo Tufano on 03/12/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "RadioListWindowController.h"

#import "RadiozAppDelegate.h"
#import "CoreDataController.h"
#import <ParseOSX/Parse.h>
#import "SDCloudUserDefaults.h"

@interface RadioListWindowController ()

@end

@implementation RadioListWindowController

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
    // Get shared coredata context
    self.sharedManagedObjectContext = ((RadiozAppDelegate *)[[NSApplication sharedApplication] delegate]).coreDataController.mainThreadContext;
    [self.arrayController setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    self.window.backgroundColor = [NSColor colorWithDeviceRed:240.0/255.0 green:198.0/255.0 blue:150.0/255.0 alpha:1.0];
    self.window.title = NSLocalizedString(@"Radio List", @"");
    [self.theTable setDoubleAction:@selector(radioDoubleClicked:)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainUIisBusy:) name:kMainUIBusy object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainUIisReady:) name:kMainUIReady object:nil];
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

-(void)saveRadioError:(NSString *)theError forUrl:(NSString *)Url
{
    // Save favorite to Parse.
    PFObject *err = [PFObject objectWithClassName:@"RadioError"];
    err[@"pUUID"] = [SDCloudUserDefaults stringForKey:@"pUUID"];
    if(Url)
        err[@"currentRadioRedirectorURL"] = Url;
    err[@"error"] = theError;
    [err saveEventually];
}

- (IBAction)radioDoubleClicked:(id)sender
{
    DLog(@"Table doublecliked on row %ld and column %ld.", self.theTable.clickedRow, self.theTable.clickedColumn);
    // if it's not a doubleclick on the header sent the action through for processing
    if(self.theTable.clickedRow != -1)
        [self radioSelected:sender];
}

- (IBAction)radioSelected:(id)sender
{
    // If nothing is selected return
    if(self.theTable.selectedRow == -1)
        return;
    // Disable user interaction to avoid double clicks.
//    self.theTable.userInteractionEnabled = NO;
    // We have a radio, now get the best streaming URL we can get.
    Radio *selectedRadio =  [self.arrayController.arrangedObjects objectAtIndex:self.theTable.selectedRow];

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
                 NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
                 NSTextCheckingResult *result = [detector firstMatchInString:redirectorData options:0 range:NSMakeRange(0, [redirectorData length])];
                 if(result && result.range.location != NSNotFound)
                 {
                     DLog(@"Found URL: %@", result.URL);
                     self.theSelectedStreamURL = [result.URL absoluteString];
                     // call the delegate on main thread
                     dispatch_async(dispatch_get_main_queue(), ^{
                         DLog(@"calling delegate");
                         [self.delegate radioListWindowControllerDidSelect:self withObject:selectedRadio];
//                         [self.window performClose:self];
                     });
                 }
                 else
                 {
                     NSString *temp = NSLocalizedString(@"URL not found in redirector.", @"");
                     NSLog(@"%@", temp);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self saveRadioError:temp forUrl:[res.URL absoluteString]];
//                         tableView.userInteractionEnabled = YES;
                         NSAlert *alert = [[NSAlert alloc] init];
                         [alert setInformativeText:temp];
                         [alert setMessageText:NSLocalizedString(@"Error", @"")];
                         [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
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
//                     tableView.userInteractionEnabled = YES;
                     NSAlert *alert = [[NSAlert alloc] init];
                     [alert setInformativeText:temp];
                     [alert setMessageText:NSLocalizedString(@"Error", @"")];
                     [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
                 });
             }
         }];
    }
//    else
//        tableView.userInteractionEnabled = YES;
}

- (IBAction)search:(id)sender
{
    NSString *searchString = [sender stringValue];
    NSString *queryString = nil;
    if(![searchString isEqualToString:@""])
    {
        // Complex NSPredicate needed to match any word in the search string
        NSArray *terms = [searchString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for(NSString *term in terms)
        {
            if([term length] == 0)
                continue;
            if(queryString == nil)
                queryString = [NSString stringWithFormat:@"searchkey contains[cd] \"%@\"", term];
            else
                queryString = [queryString stringByAppendingFormat:@" AND searchkey contains[cd] \"%@\"", term];
        }
    }
    else
        queryString = @"searchkey like[c] \"*\"";
    DLog(@"Fetching again. Query string is: '%@'", queryString);
    self.arrayController.filterPredicate = [NSPredicate predicateWithFormat:queryString];
}

@end
