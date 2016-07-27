#import <Foundation/Foundation.h>

@interface GFBackgroundBlockOperation : NSBlockOperation

@property (assign) BOOL automaticallyEndsBackgroundTask;

- (void)endBackgroundTask;

@end
