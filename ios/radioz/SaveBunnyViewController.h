//
//  SaveBunnyViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 15/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@interface SaveBunnyViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *key;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bunnyType;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *apiLabel;
@property (weak, nonatomic) IBOutlet UIButton *karotzIdButton;

- (IBAction)save:(id)sender;
- (IBAction)getKarotzId:(id)sender;

@end
