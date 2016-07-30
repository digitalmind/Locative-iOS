#import <UIKit/UIKit.h>

@interface UILocalNotification (Locative)

+ (void)presentLocalNotificationWithAlertBody:(NSString * __nonnull)alertBody;
+ (void)presentLocalDebugNotificationWithAlertBody:(NSString * __nonnull)alertBody;

+ (void)presentLocalNotificationWithSoundName:(NSString * __nullable)soundName alertBody:(NSString * __nonnull)alertBody;
+ (void)presentLocalNotificationWithSoundName:(NSString * __nullable)soundName alertBody:(NSString * __nonnull)alertBody userInfo:(NSDictionary * __nullable)userInfo;

@end
