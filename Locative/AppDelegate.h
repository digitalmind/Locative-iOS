#import "AFNetworking.h"
#import "GFGeofenceManager.h"
#import "GFCloudManager.h"
#import "GFRequestManager.h"
#import "GFCoreDataManager.h"
#import "Locative-Swift.h"

@import UIKit;
@import iOS_GPX_Framework;
@import MSDynamicsDrawerViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (nonatomic, strong) GFGeofenceManager *geofenceManager;
@property (nonatomic, strong) GFCloudManager *cloudManager;
@property (nonatomic, strong) GFRequestManager *requestManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, strong) Settings *settings;
@property (nonatomic, strong) GFCoreDataManager *coreDataManager;

@end
