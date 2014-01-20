//
//  SongAdder.m
//  RP HD
//
//  Created by Giacomo Tufano on 04/09/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "SongAdder.h"

#import "CoreDataController.h"
#import "RadiozAppDelegate.h"
#import "NSString+UUID.h"
#import "PiwikTracker.h"

@implementation SongAdder

-(id)initWithTitle:(NSString *)title andArtist:(NSString *)artist andCoversheet:(NSImage *)cover
{
    self = [super init];
    if (self)
    {
        _title = title;
        _artist = artist;
        _dateadded = [[NSDate alloc] init];
        NSString *temp = [NSString stringWithFormat:@"%@ - %@", title, artist];
        _sha = [[NSString alloc] initWithString:[temp sha256]];
        if(cover == nil)
            cover = [NSImage imageNamed:@"button-stellina"];
        NSBitmapImageRep *bitmap = [[cover representations] objectAtIndex:0];
        _cover = [bitmap representationUsingType:NSPNGFileType properties:nil];
//        _cover = UIImagePNGRepresentation([cover roundedThumbnail:178 withFixedScale:YES cornerSize:6 borderSize:1]);
    }
    return self;
}

-(BOOL)addSong:(NSError **)outError
{
    BOOL retValue = YES;
//    NSManagedObjectContext *addingContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    NSManagedObjectContext *addingContext = ((RadiozAppDelegate *)[[NSApplication sharedApplication] delegate]).coreDataController.mainThreadContext;
//    [addingContext setPersistentStoreCoordinator:((RadiozAppDelegate *)[[NSApplication sharedApplication] delegate]).coreDataController.psc];
    Song *theSongToBeSaved = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:addingContext];
    theSongToBeSaved.title = self.title;
    theSongToBeSaved.artist = self.artist;
    theSongToBeSaved.dateadded = self.dateadded;
    theSongToBeSaved.sha = self.sha;
    theSongToBeSaved.cover = self.cover;
    if (![addingContext save:outError])
    {
        // Log and return the error to the caller.
        NSLog(@"Unresolved error %@, %@", *outError, [*outError userInfo]);
        retValue = NO;
    }
    [[PiwikTracker sharedInstance] sendEventWithCategory:@"action" action:@"addSong" label:@""];
    return retValue;
}

@end
