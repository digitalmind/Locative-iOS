#import <Foundation/Foundation.h>
#import "GFRequest.h"

@class GFCloudFencelog;

@interface GFRequestManager : NSObject

+ (GFRequestManager *) sharedManager;
- (void) flushWithCompletion:(void(^)())cb;

/* Fencelogs */
- (void) dispatchFencelog:(GFCloudFencelog *)fencelog;

@end
