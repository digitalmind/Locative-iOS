#import "Locative-Swift.h"
#import "GeofenceManager.h"
#import "UIDevice+Locative.h"
#import "Fencelog.h"
#import "UILocalNotification+Locative.h"

#define WHICH_METHOD(number) ([number intValue] == 0)?@"POST":@"GET"

@import INTULocationManager;
@import ObjectiveSugar;
@import ObjectiveRecord;

@interface GeofenceManager () <CLLocationManagerDelegate>

@property (nonatomic, weak, readonly) AppDelegate *appDelegate;
@property (nonatomic, copy) void (^locationBlock)(CLLocation *currentLocation);
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, weak) NSOperationQueue *mainQueue;
@property (nonatomic, strong) NSOperationQueue *dispatchQueue;

@end

@implementation GeofenceManager

+ (id) sharedManager {
    static GeofenceManager *geofenceManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        geofenceManager = [[GeofenceManager alloc] init];
        [geofenceManager setup];
    });
    return geofenceManager;
}

- (void) setup {
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        return [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void) cleanup {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self geofences] each:^(CLRegion *fence) {
            __block BOOL found = NO;
            [[Geofence all] each:^(Geofence *event) {
                if([event.uuid isEqualToString:fence.identifier]) {
                    found = YES;
                }
                
            }];
            if(!found) {
                [self stopMonitoringForRegion:fence];
            }
        }];
        
        [[Geofence all] each:^(Geofence *event) {
            [self startMonitoringEvent:event];
        }];
    });
}

#pragma mark - Accessors
- (NSOperationQueue *)dispatchQueue {
    if (!_dispatchQueue) {
        _dispatchQueue = [[NSOperationQueue alloc] init];
    }
    return _dispatchQueue;
}

- (NSOperationQueue *)mainQueue {
    if (!_mainQueue) {
        _mainQueue = [NSOperationQueue mainQueue];
    }
    return _mainQueue;
}

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

#pragma mark - LocationManager Delegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusDenied) {
        if (self.locationBlock) {
            return self.locationBlock(nil);
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"%@", locations);
    
    [self setCurrentLocation:(CLLocation *)[locations first]];
    
    if([self locationBlock])
    {
        self.locationBlock(self.currentLocation);
        self.locationBlock = nil;
    }
    
    [self.locationManager stopUpdatingLocation];
}

- (void) performBackgroundTaskForRegion:(CLRegion *)region withTrigger:(NSString *)trigger {
    NSLog(@"CLRegion: %@, Trigger: %@", region, trigger);

    [self.dispatchQueue addOperation:[BackgroundBlockOperation blockOperationWithBlock:^{
        [self performUrlRequestForRegion:region withTrigger:trigger];
    }]];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self performBackgroundTaskForRegion:region withTrigger:GFEnter];
    [self cleanup];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self performBackgroundTaskForRegion:region withTrigger:GFExit];
    [self cleanup];
}

- (void) performUrlRequestForRegion:(CLRegion *)region withTrigger:(NSString *)trigger {
    Geofence *event = [Geofence where:[NSString stringWithFormat:@"uuid == '%@'", region.identifier]].first;
    NSLog(@"uuid == '%@'", region.identifier);
    
    if(event) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[event.latitude doubleValue] longitude:[event.longitude doubleValue]];
        NSLog(@"got location update: %@", location);
        if ([trigger isEqualToString:GFEnter] && !([event.triggers integerValue] & TriggerOnEnter)) {
            return;
        }
        
        if ([trigger isEqualToString:GFExit] && !([event.triggers integerValue] & TriggerOnExit)) {
            return;
        }
        
        NSString *relevantUrl = ([trigger isEqualToString:GFEnter])?[event enterUrl]:[event exitUrl];
        NSString *url = ([relevantUrl length] > 0)?relevantUrl:[[self.appDelegate.settings globalUrl] absoluteString];
        BOOL useGlobalUrl = ([relevantUrl length] == 0);
        NSString *eventId = ([[event customId] length] > 0)?[event customId]:[event uuid];
        NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSDate *timestamp = [NSDate date];
        
        NSDictionary *parameters = @{@"id":eventId,
                                     @"trigger":trigger,
                                     @"device":deviceId,
                                     @"device_type": @"iOS",
                                     @"device_model": [UIDevice locative_deviceModel],
                                     @"latitude":[NSNumber numberWithDouble:location.coordinate.latitude],
                                     @"longitude":[NSNumber numberWithDouble:location.coordinate.longitude],
                                     @"timestamp": [NSString stringWithFormat:@"%f", [timestamp timeIntervalSince1970]]};

        if([url length] > 0) {
            [self.mainQueue addOperationWithBlock:^{
                HttpRequest *httpRequest = [HttpRequest create];
                httpRequest.url = url;
                httpRequest.method = WHICH_METHOD([event enterMethod]);
                httpRequest.parameters = parameters;
                httpRequest.eventType = event.type;
                httpRequest.timestamp = timestamp;
                httpRequest.uuid = [[NSUUID UUID] UUIDString];
                
                if (useGlobalUrl) {
                    if ([self.appDelegate.settings httpBasicAuthEnabled]) {
                        httpRequest.httpAuth = [NSNumber numberWithBool:YES];
                        httpRequest.httpAuthUsername = [self.appDelegate.settings httpBasicAuthUsername];
                        httpRequest.httpAuthPassword = [self.appDelegate.settings httpBasicAuthPassword];
                    }
                } else {
                    if ([event.httpAuth boolValue]) {
                        httpRequest.httpAuth = [NSNumber numberWithBool:YES];
                        httpRequest.httpAuthUsername = event.httpUser;
                        httpRequest.httpAuthPassword = event.httpPasswordSecure;
                    }
                }
                
                [httpRequest save];
                [self.appDelegate.requestManager flushWithCompletion:nil];
            }];
        } else {
            Fencelog *fencelog = [[Fencelog alloc] init];
            fencelog.locationId = eventId;
            fencelog.latitude = @(location.coordinate.latitude);
            fencelog.longitude = @(location.coordinate.longitude);
            fencelog.eventType = trigger;
            fencelog.fenceType = event.type.intValue == 0 ? @"geofence" : @"ibeacon";
            fencelog.httpResponse = @"<No HTTP request has been performed>";
            [self.appDelegate.requestManager dispatchFencelog:fencelog];
            if (self.appDelegate.settings.notifyOnSuccess.boolValue) {
                [self.appDelegate.requestManager presentLocalNotification:
                 [NSString stringWithFormat:NSLocalizedString(@"%@ has been %@.", @"Fencelog-only notification string"),
                  eventId, [self localizedTriggerString:trigger]] success:YES];
            }
        }
    }
}

- (NSString *)localizedTriggerString:(NSString *)event {
    if ([event isEqualToString:@"enter"]) {
        return NSLocalizedString(@"entered", "Fencelog notification entered");
    }
    if ([event isEqualToString:@"exit"]) {
        return NSLocalizedString(@"left", @"Fencelog notification left");
    }
    return NSLocalizedString(@"triggered", @"Fencelog notification triggered");
}

#pragma mark - Public Methods
- (NSArray<__kindof CLRegion*>*) geofences {
    return [[self.locationManager monitoredRegions] allObjects];
}

- (void) startMonitoringForRegion:(CLRegion *)region {
    [[self locationManager] startMonitoringForRegion:region];
}

- (void) stopMonitoringForRegion:(CLRegion *)region {
    [[self locationManager] stopMonitoringForRegion:region];
}

- (void) stopMonitoringEvent:(Geofence *)event {
    [self.geofences enumerateObjectsUsingBlock:^(__kindof CLRegion * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToString:event.uuid]) {
            [self stopMonitoringForRegion:obj];
        }
    }];
}

- (void) startMonitoringEvent:(Geofence *)event {
    if ([event.type intValue] == GeofenceTypeGeofence) {
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([event.latitude doubleValue], [event.longitude doubleValue])
                                                                     radius:[event.radius doubleValue]
                                                                 identifier:event.uuid];
        [self startMonitoringForRegion:region];
    } else {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:event.iBeaconUuid]
                                                                         major:[event.iBeaconMajor longLongValue]
                                                                         minor:[event.iBeaconMinor longLongValue]
                                                                    identifier:event.uuid];
        [self startMonitoringForRegion:region];
    }
}

#pragma mark - Current Location
- (void) performAfterRetrievingCurrentLocation:(void (^)(CLLocation *currentLocation))block {
    self.locationBlock = block;
    __weak typeof (self) weakSelf = self;
    [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyRoom
                                                                     timeout:10.0
                                                        delayUntilAuthorized:YES
                                                                       block:
     ^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
         // only invoke block if it's not been nulled
         // fixes https://fabric.io/locative/ios/apps/com.marcuskida.geofancy/issues/573d9287ffcdc042501238c9
         __strong typeof (self) strongSelf = weakSelf;
         if (strongSelf.locationBlock) {
             strongSelf.locationBlock(currentLocation);
         }
     }];
}

@end
