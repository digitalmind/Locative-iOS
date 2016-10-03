#import <Foundation/Foundation.h>

#import "Fencelog.h"

typedef enum {
    CloudManagerSignupErrorNoError = 0,
    CloudManagerSignupErrorUserExisting,
    GFCloudManagerSignupErrorGeneric
} CloudManagerSignupError;

@class Geofence;
@class Settings;

NS_ASSUME_NONNULL_BEGIN

@interface CloudManager : NSObject

- ( instancetype)init __attribute__((unavailable("Please use `initWithSettings:` instead")));
- (instancetype)initWithSettings:(Settings * __nullable)settings;

- (void) signupAccountWithUsername:(NSString *)username andEmail:(NSString *)email andPassword:(NSString *)password onFinish:(nullable void(^)(NSError *__nullable error, CloudManagerSignupError gfcError))finish;
- (void) loginToAccountWithUsername:(NSString *)username andPassword:(NSString *)password onFinish:(nullable void(^)(NSError *__nullable error, NSString *__nullable sessionId))finish;
- (void) checkSessionWithSessionId:(NSString *)sessionId onFinish:(nullable void(^)(NSError *__nullable error))finish;

- (void) dispatchCloudFencelog:(Fencelog *)fencelog onFinish:(nullable void(^)(NSError *__nullable error))finish;
- (void) validateSessionWithCallback:(nullable void(^)(BOOL valid))cb;
- (void) validateSession;
- (void) loadGeofences:(nullable void(^)(NSError *__nullable error, NSArray *__nullable geofences))completion;
- (void) uploadGeofence:(Geofence *)geofence onFinish:(nullable void(^)(NSError *__nullable error))finish;

NS_ASSUME_NONNULL_END

@end
