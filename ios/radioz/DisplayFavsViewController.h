//
//  DisplayFavsViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 04/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

#import "Parse/Parse.h"

@class DisplayFavsViewController;

@protocol DisplayFavsViewControllerDelegate <NSObject>

- (void)displayFavsViewControllerDidCancel:(DisplayFavsViewController *)controller;
- (void)displayFavsViewControllerDidSelect:(DisplayFavsViewController *)controller withObject:(PFObject *)favorite;

@end

@interface DisplayFavsViewController : PFQueryTableViewController

@property (weak, nonatomic) id<DisplayFavsViewControllerDelegate> delegate;

- (IBAction)cancel:(id)sender;

@end
