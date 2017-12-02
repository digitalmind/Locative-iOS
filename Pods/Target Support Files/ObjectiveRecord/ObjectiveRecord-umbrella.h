#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CoreDataManager.h"
#import "NSManagedObject+ActiveRecord.h"
#import "NSManagedObject+Mappings.h"
#import "ObjectiveRecord.h"

FOUNDATION_EXPORT double ObjectiveRecordVersionNumber;
FOUNDATION_EXPORT const unsigned char ObjectiveRecordVersionString[];

