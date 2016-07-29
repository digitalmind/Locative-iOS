#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "Geofence.h"
//#import "CloudManager.h"

typedef enum : NSUInteger {
    TriggerOnEnter = (0x1 << 0), // => 0x00000001
    TriggerOnExit   = (0x1 << 1) // => 0x00000010
} GeofenceTrigger;

static NSString *const GFEnter = @"enter";
static NSString *const GFExit = @"exit";

@interface GeofenceManager : NSObject

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
