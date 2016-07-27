#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "Geofence.h"
#import "GFCloudManager.h"

typedef enum : NSUInteger {
    GFTriggerOnEnter = (0x1 << 0), // => 0x00000001
    GFTriggerOnExit   = (0x1 << 1) // => 0x00000010
} GFGeofenceTrigger;

static NSString *const GFEnter = @"enter";
static NSString *const GFExit = @"exit";

@interface GFGeofenceManager : NSObject

#pragma mark - Initialization
+ (id) sharedManager;
- (void) cleanup;

#pragma mark - Accessors
- (NSArray *) geofences;

#pragma mark - Region Monitoring
- (void) startMonitoringForRegion:(CLRegion *)region;
- (void) stopMonitoringForRegion:(CLRegion *)region;

- (void) startMonitoringEvent:(Geofence *)event;
- (void) stopMonitoringEvent:(Geofence *)event;

#pragma mark - Current Location
- (void) performAfterRetrievingCurrentLocation:(void(^)(CLLocation *currentLocation))block;

@end
