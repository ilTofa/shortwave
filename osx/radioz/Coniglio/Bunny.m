//
//  Bunny.m
//  radioz
//
//  Created by Giacomo Tufano on 16/04/12.
//  ©2014 Giacomo Tufano.
//  Licensed under MIT license. See LICENSE file or http://www.opensource.org/licenses/mit-license.php
//

#import "Bunny.h"

#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>
#import "keys.h"

// return a random number between 0 and limit inclusive.
int rand_lim(int limit) 
{
    int divisor = RAND_MAX/(limit+1);
    int retval;
    
    do { 
        retval = rand() / divisor;
    } while (retval > limit);
    
    return retval;
}

@implementation Bunny

- (NSString *)newB64forData:(NSData*)theData 
{    
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

-(void)errorInAnswer:(NSString *)dataReceived
{
    self.lastMessage = [NSString stringWithFormat:NSLocalizedString(@"Error in answer from server: %@", @""), dataReceived];
    NSLog(@"Error from server: %@", self.lastMessage);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSRange errorPosition = [dataReceived rangeOfString:@"<code>" options:NSCaseInsensitiveSearch];
        NSRange tempRange = [dataReceived rangeOfString:@"</code>" options:NSCaseInsensitiveSearch];
        if(errorPosition.location != NSNotFound && tempRange.location != NSNotFound)
        {
            NSRange errorRange;
            errorRange.location = errorPosition.location + errorPosition.length;
            errorRange.length = tempRange.location - errorRange.location;
            NSString *errorMessage = [dataReceived substringWithRange:errorRange];
            self.lastMessage = [NSString stringWithFormat:NSLocalizedString(@"Error in answer from server: %@", @""), errorMessage];
        }
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:self.lastMessage];
        [alert setMessageText:NSLocalizedString(@"Error", @"")];
        [alert runModal];
    });
}

// Get info
- (BOOL) sendRequestAndParse:(NSString *)urlString withVisibleErrors:(BOOL)errorsToTheUser
{
	NSURL *url;
	DLog(@"Parser initing with URL: %@", urlString);
	url = [NSURL URLWithString:urlString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url 
												cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
											timeoutInterval:30];
	NSData *xmlData;
	NSHTTPURLResponse *response;
	NSError *error;
    
	xmlData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if(response.statusCode != 200)
    {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error communicating with Violet servers: %d", @""), response.statusCode];
        if(errorsToTheUser)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setInformativeText:message];
                [alert setMessageText:NSLocalizedString(@"Error", @"")];
                [alert runModal];
            });
        }
        else
            NSLog(@"%@", message);
        if(self.keepaliveTimer)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.keepaliveTimer invalidate];
                self.keepaliveTimer = nil;
            });
        }
        return NO;
    }
    
//	NSLog(@"xmlData: %@", xmlData);
	if(!xmlData)
	{
		self.lastMessage = [NSString stringWithFormat:NSLocalizedString(@"Error reading URL: %@", @""), [url absoluteString]];
        if(errorsToTheUser)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setInformativeText:self.lastMessage];
                [alert setMessageText:NSLocalizedString(@"Error", @"")];
                [alert runModal];
            });
        }
        else
            NSLog(@"%@", self.lastMessage);
        if(self.keepaliveTimer)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.keepaliveTimer invalidate];
                self.keepaliveTimer = nil;
            });
        }
		return NO;
	}
    // Look for "ok"
//    NSData *okText = [@"ok" dataUsingEncoding:NSUTF8StringEncoding];
    NSString *dataReceived = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
    NSRange lookingIn;
    lookingIn.location = 0;
    lookingIn.length = [xmlData length];
    NSRange dataFound = [dataReceived rangeOfString:@"ok" options:NSCaseInsensitiveSearch]; // [xmlData rangeOfData:okText options:0 range:lookingIn];
    // If not found OK, look for terminate.
    if(dataFound.location == NSNotFound)
        dataFound = [dataReceived rangeOfString:@"terminated" options:NSCaseInsensitiveSearch]; // [xmlData rangeOfData:okText options:0 range:lookingIn];
    // If still nothing, return NO
    if(dataFound.location == NSNotFound)
    {
        self.lastMessage = [NSString stringWithFormat:NSLocalizedString(@"Error in answer from server: %@", @""), dataReceived];
        NSLog(@"Error from server: %@", self.lastMessage);
        if(errorsToTheUser)
            [self errorInAnswer:dataReceived];
        if(self.keepaliveTimer)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.keepaliveTimer invalidate];
                self.keepaliveTimer = nil;
            });
        }
        return NO;
    }
    // request successful
    self.lastMessage = @"OK";
    return YES;
}

// Start Karotz session

- (BOOL)startKarotzSession
{
    NSURL *url;
    
    NSString *key = kSecret;
    NSString *data = [NSString stringWithFormat:@"apikey=%@&installid=%@&once=%d&timestamp=%ld", kAPIKey, self.key, rand(), time(NULL)];
    DLog(@" Key: <%@>\nData: <%@>", key, data);
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
  
    DLog(@"HMAC: <%@>", [self newB64forData:HMAC]);

    NSString *urlString = [[NSString stringWithFormat:@"http://api.karotz.com/api/karotz/start?%@&signature=%@", data, [self newB64forData:HMAC]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    DLog(@"urlString: <%@>", urlString);
    
	url = [NSURL URLWithString:urlString];
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url 
												cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
											timeoutInterval:30];
	NSData *xmlData;
	NSHTTPURLResponse *response;
	NSError *error;
	xmlData = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
    if(response.statusCode != 200)
    {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error communicating with Violet servers: %d", @""), response.statusCode];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setInformativeText:message];
            [alert setMessageText:NSLocalizedString(@"Error", @"")];
            [alert runModal];
        });
        return NO;
    }

    NSString *answer = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	if(!xmlData || [answer isEqualToString:@""])
	{
		self.lastMessage = [NSString stringWithFormat:@"Error reading URL: %@", [url absoluteString]];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setInformativeText:self.lastMessage];
            [alert setMessageText:NSLocalizedString(@"Error", @"")];
            [alert runModal];
        });
		return NO;
	}
    DLog(@"The answer is: %@", answer);
    if([answer rangeOfString:@"START"].location == NSNotFound)
    {
        [self errorInAnswer:answer];
		return NO;
    }
    NSRange interactiveIdLocation = [answer rangeOfString:@"<interactiveId>"];
    if(interactiveIdLocation.location == NSNotFound)
    {
		NSLog(@"Error! <interactiveID> not found in: %@", answer);
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error in answer from server: %@", @""), @"<interactiveID> not found"];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setInformativeText:message];
            [alert setMessageText:NSLocalizedString(@"Error", @"")];
            [alert runModal];
        });
		return NO;
    }
    NSRange endInteractiveIdLocation = [answer rangeOfString:@"</interactiveId>"];
    if(endInteractiveIdLocation.location == NSNotFound)
    {
		NSLog(@"Error! </interactiveID> not found in: %@", answer);
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"Error in answer from server: %@", @""), @"</interactiveID> not found"];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setInformativeText:message];
            [alert setMessageText:NSLocalizedString(@"Error", @"")];
            [alert runModal];
        });
		return NO;
    }
    NSRange interactiveIdRange;
    interactiveIdRange.location = interactiveIdLocation.location + interactiveIdLocation.length;
    interactiveIdRange.length = endInteractiveIdLocation.location - interactiveIdRange.location;
    self.interactiveId = [answer substringWithRange:interactiveIdRange];
    DLog(@"interactiveId: <%@>", self.interactiveId);
    // Setup the keepalive timer for the session (Karotz only)...
    if([self.isKarotz boolValue])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Starting keepalive timer");
            self.keepaliveTimer = [NSTimer scheduledTimerWithTimeInterval:45 target:self selector:@selector(keepaliveKarotzSession:) userInfo:nil repeats:YES];
            [self.keepaliveTimer fire];
        });
    }
    return YES;
}

- (BOOL)startRadio:(NSString *)url
{
    NSString *radioStartURL;
    if([self.isKarotz boolValue])
    {
        if(![self startKarotzSession])
            return NO;
        radioStartURL = [NSString stringWithFormat:@"http://api.karotz.com/api/karotz/multimedia?action=play&url=%@&interactiveid=%@", [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], self.interactiveId];
    }
    else    // nabaztag code path
    {
        radioStartURL = [NSString stringWithFormat:@"http://www.nabaztag.com/nabaztags/%@/play?url=%@", self.key, [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    DLog(@"About to send: %@", radioStartURL);
    if(![self sendRequestAndParse:radioStartURL withVisibleErrors:YES])
        return NO;
    return YES;
}

// Stop radio
// if successful returns YES and lastMessage == EARPOSITIONSENT
// This is an hack... to stop the webradio, we send the word "stop".
- (BOOL)stopRadio
{
    NSString *radioStopURL;
    if([self.isKarotz boolValue])
        radioStopURL = [NSString stringWithFormat:@"http://api.karotz.com/api/karotz/interactivemode?action=stop&interactiveid=%@", self.interactiveId];
    else
        radioStopURL = [NSString stringWithFormat:@"http://www.nabaztag.com/nabaztags/%@/tts/fr?text=stop", self.key];
	DLog(@"About to send: %@", radioStopURL);
	if(![self sendRequestAndParse:radioStopURL withVisibleErrors:YES])
		return NO;
    if(self.keepaliveTimer)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.keepaliveTimer invalidate];
            self.keepaliveTimer = nil;
        });
    }
	return YES;
}

-(void)keepaliveKarotzSession:(NSTimer *)timer
{
    // http://api.karotz.com/api/karotz/led?action=light&color=FF5500&interactiveid=
    if(!self.interactiveId)
    {
        NSLog(@"Warning: Invalidating karotz timer inside the handler!");
        [timer invalidate];
        timer = nil;
    }
    // Some random (light) color.
    const CGFloat *currentColors = CGColorGetComponents([NSColor colorWithDeviceHue:self.ledColor saturation:1.0 brightness:1.0 alpha:1.0].CGColor);
    NSUInteger thisColor = currentColors[0] * 16777216 + currentColors[1] * 65536 + currentColors[0] * 256;
    self.ledColor += 0.01667;
    if(self.ledColor >= 1.0)
        self.ledColor = 0.0;
    NSString *keepaliveUrl = [NSString stringWithFormat:@"http://api.karotz.com/api/karotz/led?action=light&color=%06lX&interactiveid=%@", thisColor, self.interactiveId];
    DLog(@"About to send keepalive for hue %.2f, RGB #%06lX", self.ledColor, thisColor);
    [self sendRequestAndParse:keepaliveUrl withVisibleErrors:NO];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"name: %@, key: %@, is a %@.", self.name, self.key, [self.isKarotz boolValue] ? @"Karotz" : @"Nabaztag"];
}

-(void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.name];
    [coder encodeObject:self.key];
    [coder encodeObject:self.isKarotz];
}

-(id)initWithCoder:(NSCoder*)coder
{
    if (self=[super init]) 
    {
        [self setName:[coder decodeObject]];
        [self setKey:[coder decodeObject]];
        [self setIsKarotz:[coder decodeObject]];
        [self setInteractiveId:nil];
        [self setLedColor:0.52];
    }
    return self;
}

- (id)initWithName:(NSString *)name key:(NSString *)key asKarotz:(BOOL)isKarotz
{
    self = [super init];
    if (self) 
    {
        _name = name;
        _key = key;
        _isKarotz = @(isKarotz);
        _interactiveId = nil;
        _ledColor = 0.52;
    }
    return self;
}

-(void)dealloc
{
    self.lastMessage = nil;
    self.name = nil;
    self.key = nil;
    self.isKarotz = nil;
    self.interactiveId = nil;
}

@end
