@import Foundation;

@interface BackgroundBlockOperation : NSBlockOperation

@property (assign) BOOL automaticallyEndsBackgroundTask;

- (void)endBackgroundTask;

@end
