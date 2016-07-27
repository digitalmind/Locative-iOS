@import Foundation;

#import "HttpRequest.h"

@class Fencelog;

@interface HttpRequestManager : NSObject

+ (HttpRequestManager *) sharedManager;

- (void) flushWithCompletion:(void(^)())cb;
- (void) dispatchFencelog:(Fencelog *)fencelog;

@end
