//
//  BunniesViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 15/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

#import "SDCloudUserDefaults.h"
#import "Bunny.h"

@class BunniesViewController;

@protocol BunniesViewControllerDelegate <NSObject>

- (void)bunniesViewControllerDidCancel:(BunniesViewController *)controller;
- (void)bunniesViewControllerDidSelect:(BunniesViewController *)controller withObject:(Bunny *)theBunny;
- (void)bunniesViewControllerWantsBunnyPlayStopped:(BunniesViewController *)controller;

@end

@interface BunniesViewController : UITableViewController

@property (weak, nonatomic) id<BunniesViewControllerDelegate> delegate;
@property (strong, nonatomic) NSMutableArray *theBunniesArray;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;

- (IBAction)stopBunnies:(id)sender;

@end
