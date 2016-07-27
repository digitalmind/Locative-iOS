@import Foundation;
@import ObjectiveRecord;

@interface GFCoreDataManager : NSObject

@property (nonatomic, strong) CoreDataManager *coreDataManager;

- (instancetype)initWithModel:(NSString *)model;

@end
