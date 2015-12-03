//
//  GFSettings.m
//  Geofancy
//
//  Created by Marcus Kida on 09.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "GFSettings.h"

#define kOldSettingsFilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"settings.plist"]
#define kNewSettingsFilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@".settings.plist"]
#define kDefaultsContainer [[NSUserDefaults alloc] initWithSuiteName:@"group.marcuskida.Geofancy"]

@implementation GFSettings

- (instancetype)init {
    if ([[NSFileManager defaultManager] fileExistsAtPath:kOldSettingsFilePath]) {
        [[NSFileManager defaultManager] moveItemAtPath:kOldSettingsFilePath toPath:kNewSettingsFilePath error:nil];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithFile:kNewSettingsFilePath] ?: [super init];
}

- (void) persist
{
    [NSKeyedArchiver archiveRootObject:self toFile:kNewSettingsFilePath];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if(!self)
    {
        return nil;
    }

    self.globalUrl = [aDecoder decodeObjectForKey:@"globalUrl"];
    self.appHasBeenStarted = [aDecoder decodeObjectForKey:@"appHasBeenStarted"];
    self.globalHttpMethod = [aDecoder decodeObjectForKey:@"globalHttpMethod"];
    self.notifyOnSuccess = [aDecoder decodeObjectForKey:@"notifyOnSuccess"];
    self.notifyOnFailure = [aDecoder decodeObjectForKey:@"notifyOnFailure"];
    self.soundOnNotification = [aDecoder decodeObjectForKey:@"soundOnNotification"];
    self.httpBasicAuthEnabled = [aDecoder decodeObjectForKey:@"httpBasicAuthEnabled"];
    self.httpBasicAuthUsername = [aDecoder decodeObjectForKey:@"httpBasicAuthUsername"];
    self.httpBasicAuthPassword = [aDecoder decodeObjectForKey:@"httpBasicAuthPassword"];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.globalUrl forKey:@"globalUrl"];
    [aCoder encodeObject:self.appHasBeenStarted forKey:@"appHasBeenStarted"];
    [aCoder encodeObject:self.globalHttpMethod forKey:@"globalHttpMethod"];
    [aCoder encodeObject:self.notifyOnSuccess forKey:@"notifyOnSuccess"];
    [aCoder encodeObject:self.notifyOnFailure forKey:@"notifyOnFailure"];
    [aCoder encodeObject:self.soundOnNotification forKey:@"soundOnNotification"];
    [aCoder encodeObject:self.httpBasicAuthEnabled forKey:@"httpBasicAuthEnabled"];
    [aCoder encodeObject:self.httpBasicAuthUsername forKey:@"httpBasicAuthUsername"];
    [aCoder encodeObject:self.httpBasicAuthPassword forKey:@"httpBasicAuthPassword"];
}

- (void) setApiToken:(NSString *)apiToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apiToken forKey:kCloudSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setApiTokenForContainer:apiToken];
}

- (void) removeApiToken
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCloudSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self removeApiTokenFromContainer];
}

- (NSString *) apiToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kCloudSession];
}

- (void)setApiTokenForContainer:(NSString *)apiToken
{
    [kDefaultsContainer setObject:apiToken forKey:@"sessionId"];
    [kDefaultsContainer synchronize];
    
}

- (void)removeApiTokenFromContainer
{
    [kDefaultsContainer removeObjectForKey:@"sessionId"];
    [kDefaultsContainer synchronize];
}

@end
