#import <Foundation/Foundation.h>

#import "Fencelog.h"

typedef enum {
    CloudManagerSignupErrorNoError = 0,
    CloudManagerSignupErrorUserExisting,
    GFCloudManagerSignupErrorGeneric
} CloudManagerSignupError;

@class Geofence;
@class Settings;

@interface CloudManager : NSObject

- (nullable instancetype)init __attribute__((unavailable("Please use `initWithSettings:` instead")));
- (nonnull instancetype)initWithSettings:(Settings * __nullable)settings;

- (void) signupAccountWithUsername:(NSString * __nonnull)username andEmail:(NSString *__nonnull)email andPassword:(NSString *__nonnull)password onFinish:(nullable void(^)(NSError *__nullable error, CloudManagerSignupError gfcError))finish;
- (void) loginToAccountWithUsername:(NSString *__nonnull)username andPassword:(NSString *__nonnull)password onFinish:(nullable void(^)(NSError *__nullable error, NSString *__nullable sessionId))finish;
- (void) checkSessionWithSessionId:(NSString *__nonnull)sessionId onFinish:(nullable void(^)(NSError *__nullable error))finish;

- (void) dispatchCloudFencelog:(Fencelog *__nonnull)fencelog onFinish:(nullable void(^)(NSError *__nullable error))finish;
- (void) validateSessionWithCallback:(nullable void(^)(BOOL valid))cb;
- (void) validateSession;
- (void) loadGeofences:(nullable void(^)(NSError *__nullable error, NSArray *__nullable geofences))completion;
- (void) uploadGeofence:(Geofence *__nonnull)geofence onFinish:(nullable void(^)(NSError *__nullable error))finish;

@end
