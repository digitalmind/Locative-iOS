#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface HttpRequest : NSManagedObject

@property (nonatomic, retain, nullable) NSString * url;
@property (nonatomic, retain, nullable) NSString * method;
@property (nonatomic, retain, nullable) NSNumber * httpAuth;
@property (nonatomic, retain, nullable) NSString * httpAuthUsername;
@property (nonatomic, retain, nullable) NSString * httpAuthPassword;
@property (nonatomic, retain, nullable) NSDictionary *parameters;
@property (nonatomic, retain, nullable) NSNumber * eventType;
@property (nonatomic, retain, nullable) NSNumber * failCount;
@property (nonatomic, retain, nullable) NSDate * timestamp;
@property (nonatomic, retain, nullable) NSString * uuid;

@end
