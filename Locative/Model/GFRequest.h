#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface GFRequest : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * method;
@property (nonatomic, retain) NSNumber * httpAuth;
@property (nonatomic, retain) NSString * httpAuthUsername;
@property (nonatomic, retain) NSString * httpAuthPassword;
@property (nonatomic, retain) NSDictionary *parameters;
@property (nonatomic, retain) NSNumber * eventType;
@property (nonatomic, retain) NSNumber * failCount;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * uuid;

@end
