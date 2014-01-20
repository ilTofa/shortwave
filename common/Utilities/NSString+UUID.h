//
//  NSString+UUID.h
//  radioz
//
//  Created by Giacomo Tufano on 30/03/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@interface NSString (UUID)

+ (NSString *)uuid;

- (NSString *)sha256;

@end
