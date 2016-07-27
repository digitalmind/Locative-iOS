#import <Foundation/Foundation.h>

#import "Locative-Swift.h"
#import "Fencelog.h"

typedef enum {
    GFCloudManagerSignupErrorNoError = 0,
    GFCloudManagerSignupErrorUserExisting,
    GFCloudManagerSignupErrorGeneric
} GFCloudManagerSignupError;

@class Geofence;
@class GFSettings;

@interface GFCloudManager : NSObject

- (instancetype)init __attribute__((unavailable("Please use `initWithSettings:` instead")));
- (instancetype)initWithSettings:(Settings *)settings;

- (void) signupAccountWithUsername:(NSString *)username andEmail:(NSString *)email andPassword:(NSString *)password onFinish:(void(^)(NSError *error, GFCloudManagerSignupError gfcError))finish;
- (void) loginToAccountWithUsername:(NSString *)username andPassword:(NSString *)password onFinish:(void(^)(NSError *error, NSString *sessionId))finish;
- (void) checkSessionWithSessionId:(NSString *)sessionId onFinish:(void(^)(NSError *error))finish;

- (void) dispatchCloudFencelog:(Fencelog *)fencelog onFinish:(void(^)(NSError *error))finish;
- (void) validateSessionWithCallback:(void(^)(BOOL valid))cb;
- (void) validateSession;
- (void) loadGeofences:(void(^)(NSError *error, NSArray *geofences))completion;
- (void) uploadGeofence:(Geofence *)geofence onFinish:(void(^)(NSError *error))finish;

@end
