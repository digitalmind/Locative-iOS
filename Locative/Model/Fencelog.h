#import <Foundation/Foundation.h>

@interface Fencelog : NSObject

// Double
@property (strong) NSNumber *longitude;
@property (strong) NSNumber *latitude;

// Int
@property (strong) NSNumber *httpResponseCode;

// String
@property (strong) NSString *locationId;
@property (strong) NSString *httpUrl;
@property (strong) NSString *httpMethod;
@property (strong) NSString *eventType;
@property (strong) NSString *fenceType;

@end
