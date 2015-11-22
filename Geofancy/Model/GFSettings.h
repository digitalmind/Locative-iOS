//
//  GFSettings.h
//  Geofancy
//
//  Created by Marcus Kida on 09.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GFSettings : NSObject <NSCoding>

@property (strong) NSURL *globalUrl;
@property (strong) NSNumber *appHasBeenStarted;
@property (strong) NSNumber *globalHttpMethod;
@property (strong) NSNumber *notifyOnSuccess;
@property (strong) NSNumber *notifyOnFailure;
@property (strong) NSNumber *soundOnNotification;
@property (strong) NSNumber *httpBasicAuthEnabled;
@property (strong) NSString *httpBasicAuthUsername;
@property (strong) NSString *httpBasicAuthPassword;

- (void) setApiToken:(NSString *)apiToken;
- (void) removeApiToken;
- (NSString *) apiToken;
- (void) persist;

@end
