#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef enum NSUInteger {
    GeofenceTypeGeofence = 0,
    GeofenceTypeIbeacon
} GeofenceType;

@interface Geofence : NSManagedObject

@property (nonatomic, retain) NSString * customId;
@property (nonatomic, retain) NSNumber * enterMethod;
@property (nonatomic, retain) NSString * enterUrl;
@property (nonatomic, retain) NSNumber * exitMethod;
@property (nonatomic, retain) NSString * exitUrl;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSNumber * triggers;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSNumber * httpAuth;
@property (nonatomic, retain) NSString * httpPassword;
@property (nonatomic, retain) NSString * httpPasswordSecure;
@property (nonatomic, retain) NSString * httpUser;

@property (nonatomic, retain) NSString * iBeaconUuid;
@property (nonatomic, retain) NSNumber * iBeaconMajor;
@property (nonatomic, retain) NSNumber * iBeaconMinor;

+ (BOOL)maximumReachedShowingAlert:(BOOL)alert viewController:(UIViewController *)vc;

@end
