#import <Foundation/Foundation.h>
#import "HttpRequest.h"

@class Fencelog;

@interface GFRequestManager : NSObject

+ (GFRequestManager *) sharedManager;
- (void) flushWithCompletion:(void(^)())cb;

/* Fencelogs */
- (void) dispatchFencelog:(Fencelog *)fencelog;

@end
