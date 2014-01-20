//
//  RadioListCell.h
//  radioz
//
//  Created by Giacomo Tufano on 22/05/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <UIKit/UIKit.h>

@interface RadioListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *radioName;
@property (weak, nonatomic) IBOutlet UILabel *radioSite;
@property (weak, nonatomic) IBOutlet UILabel *radioTags;
@property (weak, nonatomic) IBOutlet UILabel *radioMP3;
@property (weak, nonatomic) IBOutlet UILabel *radioAAC;

@end
