#import "GFCoreDataManager.h"
#import "Locative-Swift.h"
#import "GFGeofence.h"

@import ObjectiveSugar;
@import ObjectiveRecord;

@implementation GFCoreDataManager

- (instancetype)initWithModel:(NSString *)model {
    if (self = [super init]) {
        _coreDataManager = [CoreDataManager sharedManager];
        _coreDataManager.modelName = model;
        _coreDataManager.bundle = [NSBundle bundleForClass:self.class];
        [self migrate];
        [self migrateCredentials];
    }
    return self;
}

- (void)migrate {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [self.coreDataManager applicationDocumentsDirectory];
    NSString *geofancyDatabasePath = [documentsDirectory URLByAppendingPathComponent:@"Geofancy.sqlite"].path;
    NSString *locativeDatabasePath = [documentsDirectory URLByAppendingPathComponent:@"Locative.sqlite"].path;
    
    if ([fileManager fileExistsAtPath:geofancyDatabasePath]) {
        NSError *error;
        [fileManager copyItemAtPath:geofancyDatabasePath toPath:locativeDatabasePath error:&error];
        if (!error) {
            NSError *removeError;
            [fileManager removeItemAtPath:geofancyDatabasePath error:&removeError];
        }
    }
}

- (void)migrateCredentials {
    @synchronized (self) {
        [[GFGeofence all] each:^(GFGeofence *object) {
            if (object.httpUser.lct_isNotEmpty == YES) {
                // bail out in case user is nil
                return;
            }
            SecureCredentials *credentials = [[SecureCredentials alloc] initWithService:object.uuid];
            credentials[object.httpUser] = object.httpPassword;
            [object save];
        }];
    }
}

@end
