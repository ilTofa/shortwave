//
//  main.m
//  radiozLoaded
//
//  Created by Giacomo Tufano on 20/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "NSString+csv.h"
#import "NSString+UUID.h"
#import "Radio.h"

static NSManagedObjectModel *managedObjectModel()
{
    static NSManagedObjectModel *model = nil;
    if (model != nil) {
        return model;
    }
    
    NSString *path = @"rphd";
    path = [path stringByDeletingPathExtension];
    NSURL *modelURL = [NSURL fileURLWithPath:[path stringByAppendingPathExtension:@"momd"]];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return model;
}

static NSManagedObjectContext *managedObjectContext()
{
    static NSManagedObjectContext *context = nil;
    if (context != nil) {
        return context;
    }

    @autoreleasepool {
        context = [[NSManagedObjectContext alloc] init];
        
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel()];
        [context setPersistentStoreCoordinator:coordinator];
        NSURL *url = [NSURL fileURLWithPath:@"localStore.sqlite"];
        
        NSError *error;
        NSPersistentStore *newStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:@"LocalConfig" URL:url options:nil error:&error];
        
        if (newStore == nil) {
            NSLog(@"Store Configuration Failure: %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
        }
    }
    return context;
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        // Create the managed object context
        NSManagedObjectContext *context = managedObjectContext();
        
        // Custom code here...
        NSLog(@"let's see if it works");
        
        // open original file
        NSURL *URL = [NSURL URLWithString:@"file:///Users/gt/Documents/dev/ShortWave/common/RadioLists/final/Radiolist-2bloaded.csv"];
        NSError *error;
        NSString *csvData = [[NSString alloc] initWithContentsOfURL:URL encoding:NSUTF8StringEncoding error:&error];
        if (csvData == nil)
        {
            // an error occurred
            NSLog(@"Error reading file at %@\n%@", URL, [error localizedFailureReason]);
            exit(1);
        }
        NSLog(@"csv loaded in a string %ld characters long.", [csvData length]);
        NSLog(@"Now loading arrays...");
        NSArray *rows = [csvData csvRows];
        NSLog(@"Done for %ld rows.", [rows count]);
        for (NSArray *riga in rows)
        {
            Radio *newRadio = [NSEntityDescription insertNewObjectForEntityForName:@"Radio" inManagedObjectContext:context];
            newRadio.name = [riga objectAtIndex:0];
            newRadio.url = [riga objectAtIndex:1];
            newRadio.city = [riga objectAtIndex:2];
            newRadio.country = [riga objectAtIndex:3];
            newRadio.tags = [riga objectAtIndex:4];
            newRadio.mp3_bitrate = @([[riga objectAtIndex:5] integerValue]);
            newRadio.mp3_url = [riga objectAtIndex:6];
            NSString *aac = [riga objectAtIndex:7];
            if([aac isEqualToString:@""])
            {
                newRadio.aac_bitrate = @(0);
                newRadio.aac_url = @"";
            }
            else
            {
                newRadio.aac_bitrate = @([[riga objectAtIndex:7] integerValue]);
                newRadio.aac_url = [riga objectAtIndex:8];
            }
            newRadio.searchkey = [NSString stringWithFormat:@"%@ %@ %@ %@", [newRadio.name lowercaseString], [newRadio.city lowercaseString], [newRadio.country lowercaseString], [newRadio.tags lowercaseString]];
            newRadio.sha = [newRadio.searchkey sha256];
            newRadio.dateadded = [NSDate date];
            NSLog(@"Added: <%@>", newRadio.name);
        }
        // Save the managed object context
        if (![context save:&error]) {
            NSLog(@"Error while saving %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
            exit(1);
        }
    }
    return 0;
}

