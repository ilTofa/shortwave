//
//  InfoViewController.h
//  radioz
//
//  Created by Giacomo Tufano on 28/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@interface InfoViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UITextView *textLabel;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;

- (IBAction)dismissDialog:(id)sender;

@end
