#import "AFNetworking.h"
#import "GeofenceManager.h"
#import "CloudManager.h"
#import "HttpRequestManager.h"
#import "Locative-Swift.h"

@import UIKit;
@import iOS_GPX_Framework;
@import MSDynamicsDrawerViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (nonatomic, strong) GeofenceManager *geofenceManager;
@property (nonatomic, strong) CloudManager *cloudManager;
@property (nonatomic, strong) HttpRequestManager *requestManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, strong) Settings *settings;
@property (nonatomic, strong) CoreDataStack *coreDataManager;

@end
