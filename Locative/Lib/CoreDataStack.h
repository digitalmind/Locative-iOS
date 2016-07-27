@import Foundation;
@import ObjectiveRecord;

@interface CoreDataStack : NSObject

@property (nonatomic, strong) CoreDataManager *coreDataManager;

- (instancetype)initWithModel:(NSString *)model;

@end
