import AFNetworking
import Fabric;
import Crashlytics;
import Harpy;
import iOS_GPX_Framework
import TSMessages;
import ObjectiveRecord;
import SVProgressHUD;

private extension String {
    static let reloadGeofences = "reloadGeofences"
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var cloudManager: CloudManager!
    
    let reachabilityManager = AFNetworkReachabilityManager(forDomain: "my.locative.io")
    let geofenceManager = GeofenceManager()
    let requestManager = HttpRequestManager()
    let settings = Settings().restoredSettings()
    let coreDataStack = CoreDataStack(model: "Model")
    let harpy = Harpy.sharedInstance()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window?.backgroundColor = UIColor.black
        
        // CloudManager
        cloudManager = CloudManager(settings: settings)
        
        // Fabric
        Fabric.with([Crashlytics.self])
        
        //Reachability
        reachabilityManager.startMonitoring()
        reachabilityManager.setReachabilityStatusChange { status in
            print(AFStringFromNetworkReachabilityStatus(status))
        }
        
        // Initial setup (if app has not been yet started)
        if let s = settings, let st = s.appHasBeenStarted , !st.boolValue {
            s.appHasBeenStarted = true
            s.persist()
        }
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(
            UIApplicationBackgroundFetchIntervalMinimum
        )
        
        // Setup Harpy
        harpy?.appID = "725198453"
        #if DEBUG
            harpy.debugEnabled = true
        #endif
        harpy?.presentingViewController = window?.rootViewController
        harpy?.alertType = .skip
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.cancelAllLocalNotifications()
        cloudManager.validateSession()
        harpy?.checkVersionDaily()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        settings?.persist()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.absoluteString == "locative://debug" {
            settings?.toggleDebug()
        }
        if !(url as NSURL).isFileReferenceURL() { return false }
        guard url.pathExtension == "gpx" else { return false }
        print("Opening GPX file at \(url.absoluteString)")
        importGpx(url)
        return true
    }
    
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        var type = TSMessageNotificationType.message;
        if let userInfo = notification.userInfo, let success = userInfo["success"] as? Bool  {
            type = success ? TSMessageNotificationType.success : TSMessageNotificationType.error;
        }
        TSMessage.showNotification(withTitle: notification.alertBody, type: type)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        settings?.apnsToken = deviceTokenString
        guard let token = settings?.apiToken else { return }
        cloudManager.updateSession(withSessionId: token, apnsToken: deviceTokenString) { error in
            print("Updated session: \(error)")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("failed to register for remote notifications: \(error)")
    }
}

//MARK: GPX Import
private extension AppDelegate {
    static let queueLabel = "io.locative.backgroundQueue"
    
    func importGpx(_ url: URL) {
        let controller = UIAlertController(
            title: NSLocalizedString("Note", comment: "Alert title when importing GPX"),
            message: NSLocalizedString("Would you like to keep your existing Geofences?", comment: "Alert message when importing GPX"),
            preferredStyle: .alert)
        controller.addAction(
            UIAlertAction(title: NSLocalizedString("No", comment: "No don't keep Geofences when importing GPX"), style: .default, handler: { [weak self] action in
                Geofence.deleteAll()
                self?.importGpx(url, keep: false)
            })
        )
        controller.addAction(
            UIAlertAction(title: NSLocalizedString("Yes", comment: "Yes keep Geofences when importing GPX"), style: .default, handler: { [weak self] action in
                self?.importGpx(url, keep: true)
            })
        )
        window?.rootViewController?.present(controller, animated: true, completion: nil)
    }
    
    func importGpx(_ url: URL, keep: Bool) {
        SVProgressHUD.show(withMaskType: UInt(SVProgressHUDMaskTypeClear))
        if let q = url.query , q.range(of: "openSettings=true") != nil {
            // open settings
            window?.rootViewController?.tabBarController?.selectedIndex = .settingsIndex
        }

        DispatchQueue(label: AppDelegate.queueLabel).async { [weak self] in
            guard let root = try? GPXParser.parseGPX(at: url) else {
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
            for (index, _) in [0...count].enumerated() {
                DispatchQueue.main.async(execute: { [weak self] in
                    let waypoint = root.waypoints[index]
                    let geofence = Geofence.create() as! Geofence
                    geofence.type = NSNumber(value: GeofenceType.geofence.rawValue)
                    geofence.name = (waypoint as AnyObject).comment
                    geofence.uuid = UUID().uuidString
                    geofence.customId = (waypoint as AnyObject).name
                    geofence.latitude = (waypoint as AnyObject).latitude
                    geofence.longitude = (waypoint as AnyObject).longitude
                    geofence.radius = 50
                    geofence.triggers = NSNumber(value: UInt32(TriggerOnEnter.rawValue | TriggerOnExit.rawValue) as UInt32)
                    geofence.save()
                    self?.geofenceManager.startMonitoringEvent(geofence)
                    print("Imported and started \(geofence)")
                })
            }
            DispatchQueue.main.async(execute: { [weak self] in
                self?.geofenceManager.cleanup()
                NotificationCenter.default.post(
                    name: Notification.Name(rawValue: .reloadGeofences), object: nil
                )
                SVProgressHUD.dismiss()
                self?.showAlert(false, limitExceeded: maxImportLimitExceeded, maxLimit: max, overall: overallWaypoints)
            })
        }
    }
}

//MARK: - Alert
private extension AppDelegate {
    func showAlert(_ errored: Bool, limitExceeded: Bool, maxLimit: Int, overall: Int) {
        func message(_ errored: Bool, limitExceeded: Bool, maxLimit: Int, overall: Int) -> String {
            if !errored && limitExceeded {
                return "".appendingFormat(
                    NSLocalizedString("Only %1$d of the %2$d Geofences could be imported due to the 20 Geofences limit.", comment: ""), maxLimit, overall
                )
            }
            if errored {
                return NSLocalizedString("An error occured when trying to open our GPX file, maybe it's damaged?", comment: "GPX import generic error message")
            }
            return NSLocalizedString("Your GPX file has been sucessfully imported.", comment: "GPX import success message")
        }
        
        let alert = UIAlertController(
            title: errored ? NSLocalizedString("Error", comment: "GPX import error title") : NSLocalizedString("Note", comment: "GPX import note title"),
            message: message(errored, limitExceeded: limitExceeded, maxLimit: maxLimit, overall: overall),
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(title: NSLocalizedString("OK", comment: "GPX import alert ok"), style: .default, handler: nil)
        )
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
