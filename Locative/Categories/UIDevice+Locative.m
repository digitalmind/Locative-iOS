#import "UIDevice+Locative.h"
#import <sys/utsname.h>

@implementation UIDevice (Locative)

+ (NSString *) locative_deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@end
