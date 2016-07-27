@import Foundation;

@interface Config : NSObject

@property (nonatomic, assign) BOOL backgroundFetchMessageShown;
@property (nonatomic, strong) NSDate *lastMessageFetch;
@property (nonatomic, strong, readonly) NSString *readableVersionString;

@end
