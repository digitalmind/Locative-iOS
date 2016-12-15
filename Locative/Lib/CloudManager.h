#import <Foundation/Foundation.h>

typedef enum {
    CloudManagerSignupErrorNoError = 0,
    CloudManagerSignupErrorUserExisting,
    GFCloudManagerSignupErrorGeneric
} CloudManagerSignupError;

@class Geofence;
@class Settings;
@class Fencelog;

NS_ASSUME_NONNULL_BEGIN

@interface CloudCredentials : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong, nullable) NSString *email;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *apnsToken;
@property (nonatomic, assign, getter=isRegisterable, readonly) BOOL registerable;

- (instancetype) initWithUsername:(NSString *)username email:(nullable NSString *)email password:(NSString *)password;

@end

@interface CloudManager : NSObject

- ( instancetype)init __attribute__((unavailable("Please use `initWithSettings:` instead")));
- (instancetype)initWithSettings:(Settings * __nullable)settings;

- (void) signupAccountWithCredentials:(CloudCredentials *)credentials onFinish:(nullable void(^)(NSError *__nullable error, CloudManagerSignupError gfcError))finish;
- (void) loginToAccountWithCredentials:(CloudCredentials *)credentials onFinish:(nullable void(^)(NSError *__nullable error, NSString *__nullable sessionId))finish;
- (void) checkSessionWithSessionId:(NSString *)sessionId onFinish:(nullable void(^)(NSError *__nullable error))finish;

- (void) dispatchCloudFencelog:(Fencelog *)fencelog onFinish:(nullable void(^)(NSError *__nullable error))finish;
- (void) validateSessionWithCallback:(nullable void(^)(BOOL valid))cb;
- (void) validateSession;
- (void) updateSessionWithSessionId:(NSString *)sessionId apnsToken:(NSString *)apnsToken onFinish:(void (^)( NSError * __nullable error))finish;
- (void) loadGeofences:(nullable void(^)(NSError *__nullable error, NSArray *__nullable geofences))completion;
- (void) uploadGeofence:(Geofence *)geofence onFinish:(nullable void(^)(NSError *__nullable error))finish;

NS_ASSUME_NONNULL_END

@end
