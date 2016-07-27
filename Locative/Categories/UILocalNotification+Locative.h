#import <UIKit/UIKit.h>

@interface UILocalNotification (Locative)

+ (void)presentLocalNotificationWithAlertBody:(NSString *)alertBody;
+ (void)presentLocalDebugNotificationWithAlertBody:(NSString *)alertBody;

+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody;
+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo;

@end
