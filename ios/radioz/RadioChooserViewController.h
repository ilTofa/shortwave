//
//  RadioChooserViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 22/05/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#import "Radio.h"

@class RadioChooserViewController;

@protocol RadioChooserViewControllerDelegate <NSObject>

- (void)radioChooserViewControllerDidCancel:(RadioChooserViewController *)controller;
- (void)radioChooserViewControllerDidSelect:(RadioChooserViewController *)controller withObject:(Radio *)radio;

@end

@interface RadioChooserViewController : UITableViewController <UISearchBarDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSString *searchKey;
@property (strong, nonatomic) NSString *searchText;
@property (nonatomic) NSInteger searchScope;

@property (strong, nonatomic) NSString *theSelectedStreamURL;
@property (weak, nonatomic) id<RadioChooserViewControllerDelegate> delegate;

- (IBAction)cancel:(id)sender;

@end
