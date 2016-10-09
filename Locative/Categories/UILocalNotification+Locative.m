#import "UILocalNotification+Locative.h"

@implementation UILocalNotification (Locative)

+ (void)presentLocalNotificationWithAlertBody:(NSString *)alertBody {
    [self presentLocalNotificationWithSoundName:nil alertBody:alertBody];
}

+ (void)presentLocalDebugNotificationWithAlertBody:(NSString *)alertBody {
    [self presentLocalNotificationWithAlertBody:[@"DEBUG: " stringByAppendingString:alertBody]];
}

+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody {
    [self presentLocalNotificationWithSoundName:soundName alertBody:alertBody userInfo:nil];
}

+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo {
    NSAssert(alertBody, @"alertBody is mandatory!");
    UILocalNotification *notification = [[self alloc] init];
    notification.soundName = soundName;
    notification.userInfo = userInfo;
    notification.alertBody = alertBody;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

@end
