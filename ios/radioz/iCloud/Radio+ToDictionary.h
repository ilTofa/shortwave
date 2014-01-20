//
//  Radio+ToDictionary.h
//  radioz
//
//  Created by Giacomo Tufano on 21/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "Radio.h"

@interface Radio (ToDictionary)

+(BOOL)addRadioFromDictionary:(NSDictionary *)song error:(NSError **)outError;

-(NSDictionary *)convertToDictionary;

@end
