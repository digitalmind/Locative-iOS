//
//  GFSettings.m
//  Geofancy
//
//  Created by Marcus Kida on 09.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "GFSettings.h"
#import "Locative-Swift.h"

#define kOldSettingsFilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"settings.plist"]
#define kNewSettingsFilePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@".settings.plist"]
#define kDefaultsContainer [[NSUserDefaults alloc] initWithSuiteName:@"group.marcuskida.Geofancy"]

#define SECURE_SERVICE_API_TOKEN @"ApiToken"
#define SECURE_SERVICE_GLOBAL_BASIC_AUTH @"GlobalBasicAuth"

@interface GFSettings ()

@property (nonatomic, strong) SecureCredentials *apiCredentials;
@property (nonatomic, strong) SecureCredentials *basicAuthCredentials;

@end

@implementation GFSettings

- (instancetype)init {
    if ([[NSFileManager defaultManager] fileExistsAtPath:kOldSettingsFilePath]) {
        [[NSFileManager defaultManager] moveItemAtPath:kOldSettingsFilePath toPath:kNewSettingsFilePath error:nil];
    }
    return [NSKeyedUnarchiver unarchiveObjectWithFile:kNewSettingsFilePath] ?: [super init];
}

- (void) persist {
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
    
    if (self.httpBasicAuthUsername.lct_isNotEmpty) {
        self.basicAuthCredentials[self.httpBasicAuthUsername] = self.httpBasicAuthPassword;
    }
    
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
    [aCoder encodeObject:nil forKey:@"httpBasicAuthPassword"]; // remove password from plist
    self.httpBasicAuthPassword = self.basicAuthCredentials[self.httpBasicAuthUsername];
}

#pragma mark - API token setter
- (void)setApiToken:(NSString *)apiToken {
    self.apiCredentials[SECURE_SERVICE_API_TOKEN] = apiToken;
}

- (void) old_setApiToken:(NSString *)apiToken
{
    [[NSUserDefaults standardUserDefaults] setObject:apiToken forKey:kCloudSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self setApiTokenForContainer:apiToken];
}

#pragma mark - API token removal
- (void)removeApiToken {
    self.apiCredentials[SECURE_SERVICE_API_TOKEN] = nil;
}

- (void) old_removeApiToken
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCloudSession];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self removeApiTokenFromContainer];
}

#pragma mark - API token getter
- (NSString *)apiToken {
    [self migrateApiToken];
    return (NSString *)self.apiCredentials[SECURE_SERVICE_API_TOKEN];
}

- (NSString *) old_apiToken
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kCloudSession];
}

- (void)migrateApiToken {
    if (self.old_apiToken.lct_isNotEmpty) {
        [self setApiToken:self.old_apiToken];
        [self old_removeApiToken];
    }
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

#pragma mark - Secure credentials
- (SecureCredentials *)apiCredentials {
    if (!_apiCredentials) {
        _apiCredentials = [[SecureCredentials alloc] initWithService:SECURE_SERVICE_API_TOKEN];
    }
    return _apiCredentials;
}

- (SecureCredentials *)basicAuthCredentials {
    if (!_basicAuthCredentials) {
        _basicAuthCredentials = [[SecureCredentials alloc] initWithService:SECURE_SERVICE_GLOBAL_BASIC_AUTH];
    }
    return _basicAuthCredentials;
}

@end
