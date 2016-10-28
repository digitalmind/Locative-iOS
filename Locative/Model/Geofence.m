#import "Geofence.h"
#import "Locative-Swift.h"

@import ObjectiveSugar;
@import ObjectiveRecord;

@implementation Geofence

@dynamic customId;
@dynamic enterMethod;
@dynamic enterUrl;
@dynamic exitMethod;
@dynamic exitUrl;
@dynamic latitude;
@dynamic longitude;
@dynamic name;
@dynamic radius;
@dynamic triggers;
@dynamic type;
@dynamic uuid;
@dynamic httpAuth;
@dynamic httpPassword;
@dynamic httpUser;

@dynamic iBeaconUuid;
@dynamic iBeaconMajor;
@dynamic iBeaconMinor;

+ (BOOL)maximumReachedShowingAlert:(BOOL)alert viewController:(UIViewController *)vc
{
    if ([[Geofence all] count] >= 20) {
        if (alert) {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                  message:NSLocalizedString(@"There's a maximum limit of 20 Geofences per App, please remove some Geofences before adding new ones.", nil)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
            [controller addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            [vc presentViewController:controller animated:true completion:nil];
        }
        return YES;
    }
    return NO;
}

- (void)setHttpPasswordSecure:(NSString *)httpPasswordSecure {
    self.credentials[self.httpUser] = httpPasswordSecure;
}

- (NSString *)httpPasswordSecure {
    if (self.httpPassword.lct_isNotEmpty) {
        self.credentials[self.httpPassword] = self.httpPassword;
    }
    return self.credentials[self.httpUser];
}

- (SecureCredentials *)credentials {
    return [[SecureCredentials alloc] initWithService:self.uuid];
}

@end
