import AFNetworking
import Fabric;
import Crashlytics;
import Harpy;
import iOS_GPX_Framework
import TSMessages;
import MSDynamicsDrawerViewController
import PSTAlertController;
import ObjectiveRecord;
import SVProgressHUD;
import SwiftyBeaver;

extension String {
    static let reloadGeofences = "reloadGeofences"
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var dynamicsDrawerViewController: MSDynamicsDrawerViewController!
    var cloudManager: CloudManager!
    
    let reachabilityManager = AFNetworkReachabilityManager(forDomain: "my.locative.io")
    let geofenceManager = GeofenceManager.sharedManager()
    let requestManager = HttpRequestManager.sharedManager
    let settings = Settings().restoredSettings()
    let coreDataStack = CoreDataStack(model: "Model")
    let harpy = Harpy.sharedInstance()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window?.backgroundColor = UIColor.blackColor()
        
        // SwiftyBeaver
        if let id = Environment.SwiftyBeaver.appId,
            secret = Environment.SwiftyBeaver.appSecret,
            key = Environment.SwiftyBeaver.encryptionKey where
            Environment.SwiftyBeaver.enabled {
            
            let console = ConsoleDestination()  // log to Xcode Console
            let file = FileDestination()  // log to default swiftybeaver.log file
            let cloud = SBPlatformDestination(appID: id,
                                              appSecret: secret,
                                              encryptionKey: key) // to cloud
            SwiftyBeaver.addDestination(console)
            SwiftyBeaver.addDestination(file)
            SwiftyBeaver.addDestination(cloud)
            SwiftyBeaver.info("SwiftyBeaver enabled!")
        }

        // CloudManager
        cloudManager = CloudManager(settings: settings)
        
        // Fabric
        Fabric.with([Crashlytics.self])
        
        //Reachability
        reachabilityManager.startMonitoring()
        reachabilityManager.setReachabilityStatusChangeBlock { status in
            print(AFStringFromNetworkReachabilityStatus(status))
        }
        
        // Initial setup (if app has not been yet started)
        if let s = settings, st = s.appHasBeenStarted where !st.boolValue {
            s.appHasBeenStarted = true
            s.persist()
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        dynamicsDrawerViewController = MSDynamicsDrawerViewController()
        dynamicsDrawerViewController.paneViewSlideOffAnimationEnabled = false
        dynamicsDrawerViewController.paneDragRequiresScreenEdgePan = true
        dynamicsDrawerViewController.addStylersFromArray([
            MSDynamicsDrawerScaleStyler.styler(),
            MSDynamicsDrawerFadeStyler.styler()
            ], forDirection: .Left)
        dynamicsDrawerViewController.setDrawerViewController(
            storyboard.instantiateViewControllerWithIdentifier("Menu"),
            forDirection: .Left
        )
        dynamicsDrawerViewController.paneViewController =
            storyboard.instantiateViewControllerWithIdentifier("GeofencesNav")
        dynamicsDrawerViewController.gravityMagnitude = 4.0
        window?.rootViewController = dynamicsDrawerViewController
        window?.makeKeyAndVisible()
        
        UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(
            UIApplicationBackgroundFetchIntervalMinimum
        )
        
        // Remove all pending http requests
        // TODO: Don't do this once were intentially caching all pending reqs
        HttpRequest.deleteAll()
        
        // Setup Harpy
        harpy.appID = "725198453"
        #if DEBUG
            harpy.debugEnabled = true
        #endif
        harpy.presentingViewController = window?.rootViewController
        harpy.alertType = .Skip
        
        SwiftyBeaver.verbose("App finished launching")
        return true
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        cloudManager.validateSession()
        harpy.checkVersionDaily()
        SwiftyBeaver.verbose("App became active")
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        SwiftyBeaver.debug("Open url: \(url)")
        if !url.isFileReferenceURL() { return false }
        if let ext = url.pathExtension where ext != "gpx" { return false }
        print("Opening GPX file at \(url.absoluteString)")
        importGpx(url)
        return true
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        SwiftyBeaver.debug("Perform background fetch")
        requestManager.flushWithCompletion {
            completionHandler(.NewData)
        }
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        SwiftyBeaver.debug("Did receive local notification")
        var type = TSMessageNotificationType.Message;
        if let userInfo = notification.userInfo, success = userInfo["success"] as? Bool  {
            type = success ? TSMessageNotificationType.Success : TSMessageNotificationType.Error;
        }
        TSMessage.showNotificationWithTitle(notification.alertBody, type: type)
    }
}

//MARK: GPX Import
private extension AppDelegate {
    func importGpx(url: NSURL) {
        let controller = PSTAlertController(
            title: NSLocalizedString("Note", comment: "Alert title when importing GPX"),
            message: NSLocalizedString("Would you like to keep your existing Geofences?", comment: "Alert message when importing GPX"),
            preferredStyle: .Alert)
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("No", comment: "No don't keep Geofences when importing GPX"), style: .Default, handler: { [weak self] action in
                Geofence.deleteAll()
                self?.importGpx(url, keep: false)
            })
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("Yes", comment: "Yes keep Geofences when importing GPX"), style: .Default, handler: { [weak self] action in
                self?.importGpx(url, keep: true)
            })
        )
    }
    
    func importGpx(url: NSURL, keep: Bool) {
        SVProgressHUD.showWithMaskType(UInt(SVProgressHUDMaskTypeClear))
        if let q = url.query where q.rangeOfString("openSettings=true") != nil {
            // open settings
            dynamicsDrawerViewController.paneViewController =
                UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewControllerWithIdentifier("SettingsNav")
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { [weak self] in
            guard let root = try? GPXParser.parseGPXAtURL(url) else {
                self?.showAlert(true, limitExceeded: false, maxLimit: 0, overall: 0)
                return
            }
            let max = keep ? (20 - Geofence.all().count) : 20
            var maxImportLimitExceeded = false
            var overallWaypoints = 0
            
            if root.waypoints.count > max {
                overallWaypoints = root.waypoints.count
                maxImportLimitExceeded = true
            }
            print("maxLimit: \(max), maxImportLimitExceed: \(maxImportLimitExceeded)")
            let count = maxImportLimitExceeded ? max : root.waypoints.count
            for (index, _) in [0...count].enumerate() {
                dispatch_async(dispatch_get_main_queue(), { [weak self] in
                    let waypoint = root.waypoints[index]
                    let geofence = Geofence.create() as! Geofence
                    geofence.type = NSNumber(unsignedInt: GeofenceTypeGeofence.rawValue)
                    geofence.name = waypoint.comment
                    geofence.uuid = NSUUID().UUIDString
                    geofence.customId = waypoint.name
                    geofence.latitude = waypoint.latitude
                    geofence.longitude = waypoint.longitude
                    geofence.radius = 50
                    geofence.triggers = NSNumber(unsignedInt: UInt32(TriggerOnEnter.rawValue | TriggerOnExit.rawValue))
                    geofence.save()
                    self?.geofenceManager.startMonitoringEvent(geofence)
                    print("Imported and started \(geofence)")
                })
            }
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                self?.geofenceManager.cleanup
                NSNotificationCenter.defaultCenter().postNotificationName(
                    .reloadGeofences, object: nil
                )
                SVProgressHUD.dismiss()
                self?.showAlert(false, limitExceeded: maxImportLimitExceeded, maxLimit: max, overall: overallWaypoints)
            })
        }
    }
}

//MARK: - Alert
private extension AppDelegate {
    func showAlert(errored: Bool, limitExceeded: Bool, maxLimit: Int, overall: Int) {
        func message(errored: Bool, limitExceeded: Bool, maxLimit: Int, overall: Int) -> String {
            if !errored && limitExceeded {
                return "".stringByAppendingFormat(
                    NSLocalizedString("Only %1$d of the %2$d Geofences could be imported due to the 20 Geofences limit.", comment: ""), maxLimit, overall
                )
            }
            if errored {
                return NSLocalizedString("An error occured when trying to open our GPX file, maybe it's damaged?", comment: "GPX import generic error message")
            }
            return NSLocalizedString("Your GPX file has been sucessfully imported.", comment: "GPX import success message")
        }
        
        let alert = PSTAlertController(
            title: errored ? NSLocalizedString("Error", comment: "GPX import error title") : NSLocalizedString("Note", comment: "GPX import note title"),
            message: message(errored, limitExceeded: limitExceeded, maxLimit: maxLimit, overall: overall),
            preferredStyle: .Alert
        )
        alert.addAction(
            PSTAlertAction(title: NSLocalizedString("OK", comment: "GPX import alert ok"), style: .Default, handler: nil)
        )
        alert.showWithSender(self, controller: nil, animated: true, completion: nil)
    }
}