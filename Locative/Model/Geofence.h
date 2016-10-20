#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum NSUInteger {
    GeofenceTypeGeofence = 0,
    GeofenceTypeIbeacon
} GeofenceType;

@interface Geofence : NSManagedObject

@property (nonatomic, retain, nullable) NSString * customId;
@property (nonatomic, retain, nullable) NSNumber * enterMethod;
@property (nonatomic, retain, nullable) NSString * enterUrl;
@property (nonatomic, retain, nullable) NSNumber * exitMethod;
@property (nonatomic, retain, nullable) NSString * exitUrl;
@property (nonatomic, retain, nullable) NSNumber * latitude;
@property (nonatomic, retain, nullable) NSNumber * longitude;
@property (nonatomic, retain, nullable) NSString * name;
@property (nonatomic, retain, nullable) NSNumber * radius;
@property (nonatomic, retain, nullable) NSNumber * triggers;
@property (nonatomic, retain, nullable) NSNumber * type;
@property (nonatomic, retain, nullable) NSString * uuid;
@property (nonatomic, retain, nullable) NSNumber * httpAuth;
@property (nonatomic, retain, nullable) NSString * httpPassword;
@property (nonatomic, retain, nullable) NSString * httpPasswordSecure;
@property (nonatomic, retain, nullable) NSString * httpUser;

@property (nonatomic, retain, nullable) NSString * iBeaconUuid;
@property (nonatomic, retain, nullable) NSNumber * iBeaconMajor;
@property (nonatomic, retain, nullable) NSNumber * iBeaconMinor;

+ (BOOL)maximumReachedShowingAlert:(BOOL)alert viewController:(nonnull UIViewController *)vc;

@end
