//
//  Radio.h
//  radioz
//
//  Created by Giacomo Tufano on 20/09/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Radio : NSManagedObject

@property (nonatomic, retain) NSNumber * aac_bitrate;
@property (nonatomic, retain) NSString * aac_url;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * country;
@property (nonatomic, retain) NSNumber * mp3_bitrate;
@property (nonatomic, retain) NSString * mp3_url;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * sha;
@property (nonatomic, retain) NSString * searchkey;
@property (nonatomic, retain) NSDate * dateadded;

@end
