//
//  GFCoreDataManager.m
//  Locative
//
//  Created by Marcus Kida on 1/12/2015.
//  Copyright © 2015 Marcus Kida. All rights reserved.
//

#import "GFCoreDataManager.h"

@implementation GFCoreDataManager

- (instancetype)initWithModel:(NSString *)model {
    if (self = [super init]) {
        _coreDataManager = [CoreDataManager sharedManager];
        _coreDataManager.modelName = model;
        [self migrate];
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



@end
