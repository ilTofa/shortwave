//
//  Radio+ToDictionary.m
//  radioz
//
//  Created by Giacomo Tufano on 21/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "Radio+ToDictionary.h"

#import "RadiozAppDelegate.h"
#import "CoreDataController.h"
#import "NSString+UUID.h"

@implementation Radio (ToDictionary)

-(NSDictionary *)convertToDictionary
{
    @autoreleasepool {
        NSMutableDictionary *retDictionary = [[NSMutableDictionary alloc] initWithCapacity:9];
        (retDictionary)[@"aac_bitrate"] = self.aac_bitrate;
        (retDictionary)[@"aac_url"] = self.aac_url;
        (retDictionary)[@"mp3_bitrate"] = self.mp3_bitrate;
        (retDictionary)[@"mp3_url"] = self.mp3_url;
        (retDictionary)[@"radio_city"] = self.city;
        (retDictionary)[@"radio_country"] = self.country;
        (retDictionary)[@"radio_name"] = self.name;
        (retDictionary)[@"radio_tags"] = self.tags;
        (retDictionary)[@"radio_url"] = self.url;
        return retDictionary;
    }
}

+(BOOL)addRadioFromDictionary:(NSDictionary *)song error:(NSError **)outError
{
    BOOL retValue = YES;
    NSManagedObjectContext *addingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [addingContext setPersistentStoreCoordinator:((RadiozAppDelegate *)[[UIApplication sharedApplication] delegate]).coreDataController.psc];
    Radio *newRadio = [NSEntityDescription insertNewObjectForEntityForName:@"Radio" inManagedObjectContext:addingContext];
    newRadio.name = (song)[@"radio_name"];
    newRadio.url = (song)[@"radio_url"];
    newRadio.city = (song)[@"radio_city"];
    newRadio.country = (song)[@"radio_country"];
    newRadio.tags = (song)[@"radio_tags"];
    newRadio.mp3_bitrate = (song)[@"mp3_bitrate"];
    newRadio.mp3_url = (song)[@"mp3_url"];
    newRadio.aac_bitrate = (song)[@"aac_bitrate"];
    newRadio.aac_url = (song)[@"aac_url"];
    newRadio.searchkey = [NSString stringWithFormat:@"%@ %@ %@ %@", [newRadio.name lowercaseString], [newRadio.city lowercaseString], [newRadio.country lowercaseString], [newRadio.tags lowercaseString]];
    newRadio.sha = [newRadio.searchkey sha256];
    newRadio.dateadded = [NSDate date];
    DLog(@"Added: <%@>", newRadio.name);
    // Save the managed object context
    if (![addingContext save:outError])
    {
        NSLog(@"Unresolved error %@, %@", *outError, [*outError userInfo]);
        retValue = NO;
    }
    // release the adding managed object context
    addingContext = nil;
    return retValue;
}

@end
