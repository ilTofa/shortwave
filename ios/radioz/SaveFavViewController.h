//
//  SaveFavViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 31/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@class SaveFavViewController;

@protocol SaveFavViewControllerDelegate <NSObject>
- (void)saveFavViewControllerDidCancel:(SaveFavViewController *)controller;
- (void)saveFavViewControllerDidSelect:(SaveFavViewController *)controller;
@end

@interface SaveFavViewController : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *radioNameInput;
@property (weak, nonatomic) IBOutlet UITextField *urlInput;
@property (weak, nonatomic) IBOutlet UITextField *infoInput;
@property (weak, nonatomic) IBOutlet UITextField *radioUrlInput;
@property (weak, nonatomic) IBOutlet UITextField *radioCityInput;
@property (weak, nonatomic) IBOutlet UITextField *radioCountryInput;
@property (weak, nonatomic) IBOutlet UILabel *radioNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *radioUrlLabel;
@property (weak, nonatomic) IBOutlet UILabel *radioCityLabel;
@property (weak, nonatomic) IBOutlet UILabel *radioCountryLabel;

@property (weak, nonatomic) id<SaveFavViewControllerDelegate> delegate;

@property (strong, nonatomic) NSMutableDictionary *theRadio;

- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;

- (void)configureView;

@end
