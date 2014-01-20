//
//  Bunny.h
//  radioz
//
//  Created by Giacomo Tufano on 16/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import <AppKit/AppKit.h>

@interface Bunny : NSObject <NSCoding>

@property (copy, nonatomic) NSString *name;
@property (copy, nonatomic) NSString *key;
@property (copy, nonatomic) NSString * interactiveId;
@property (strong, nonatomic) NSNumber *isKarotz;
@property (strong, nonatomic) NSTimer *keepaliveTimer;
@property (nonatomic) float ledColor;

@property (copy, nonatomic) NSString *lastMessage;

- (id)initWithName:(NSString *)name key:(NSString *)key asKarotz:(BOOL)isKarotz;
- (BOOL)startRadio:(NSString *)url;
- (BOOL)stopRadio;

@end
