import AFNetworking
import Fabric
import Crashlytics
import Harpy
import iOS_GPX_Framework
import TSMessages
import ObjectiveRecord
import SVProgressHUD
import SwiftyBeaver

private extension String {
    static let reloadGeofences = "reloadGeofences"
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var cloudManager: CloudManager!
    var geofenceManager: GeofenceManager!
    let cloudConnect = CloudConnect()
    
    let reachabilityManager = AFNetworkReachabilityManager(forDomain: "my.locative.io")
    let requestManager = HttpRequestManager()
    let settings = Settings().restoredSettings()
    let coreDataStack = CoreDataStack(model: "Model")
    let harpy = Harpy.sharedInstance()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window?.backgroundColor = UIColor.black
        geofenceManager = GeofenceManager(settings: settings, requestManager: requestManager)
        
        // CloudManager
        cloudManager = CloudManager(settings: settings)
        
        // Fabric
        Fabric.with([Crashlytics.self])
        
        //Reachability
        reachabilityManager.startMonitoring()
        reachabilityManager.setReachabilityStatusChange { status in
            SwiftyBeaver.self.info(AFStringFromNetworkReachabilityStatus(status))
        }
        
        // Initial setup (if app has not been yet started)
        if let st = settings.appHasBeenStarted , !st.boolValue {
            settings.appHasBeenStarted = true
            settings.persist()
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
        
        // SwiftyBeaver
        if !Environment.SwiftyBeaver.enabled { return true }
        guard let id = Environment.SwiftyBeaver.appId,
            let secret = Environment.SwiftyBeaver.appSecret,
            let key = Environment.SwiftyBeaver.encryptionKey else { return true }
        let console = ConsoleDestination()  // log to Xcode Console
        let file = FileDestination()  // log to default swiftybeaver.log file
        let cloud = SBPlatformDestination(appID: id,
                                          appSecret: secret,
                                          encryptionKey: key) // to cloud
        SwiftyBeaver.addDestination(console)
        SwiftyBeaver.addDestination(file)
        SwiftyBeaver.addDestination(cloud)
        SwiftyBeaver.info("SwiftyBeaver enabled!")
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        UIApplication.shared.cancelAllLocalNotifications()
        cloudManager.validateSession()
        harpy?.checkVersionDaily()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        settings.persist()
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.absoluteString == "locative://debug" {
            settings.toggleDebug()
        } else if url.absoluteString.hasPrefix("locative://login") {
            guard let token = url.absoluteString.components(separatedBy: "=").last else { return true }
            settings.apiToken = token
            settings.persist()
            NotificationCenter.default.post(name: .notificationLoginDone, object: nil)
            reloadAccountData()
        }
        if !(url as NSURL).isFileReferenceURL() { return false }
        guard url.pathExtension == "gpx" else { return false }
        SwiftyBeaver.self.debug("Opening GPX file at \(url.absoluteString)")
        importGpx(url)
        return true
    }
    
    func reloadAccountData() {
        cloudConnect.getAccountData { [weak self] account in
            self?.settings.accountData = account
            NotificationCenter.default.post(name: .notificationAccountLoaded, object: nil)
        }
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
        settings.apnsToken = deviceTokenString
        guard let token = settings.apiToken else { return }
        cloudManager.updateSession(withSessionId: token, apnsToken: deviceTokenString) { error in
            SwiftyBeaver.self.error("Updated session: \(error)")
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        SwiftyBeaver.self.error("failed to register for remote notifications: \(error)")
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
            SwiftyBeaver.self.debug("maxLimit: \(max), maxImportLimitExceed: \(maxImportLimitExceeded)")
            let count = maxImportLimitExceeded ? max : root.waypoints.count
            for (index, _) in [0...count].enumerated() {
                DispatchQueue.main.async(execute: {
                    let waypoint = root.waypoints[index]
                    let geofence = Geofence.create() as! Geofence
                    geofence.type = NSNumber(value: GeofenceType.geofence.rawValue)
                    geofence.name = (waypoint as AnyObject).comment
                    geofence.uuid = UUID().uuidString
                    geofence.customId = (waypoint as AnyObject).name
                    geofence.latitude = (waypoint as AnyObject).latitude
                    geofence.longitude = (waypoint as AnyObject).longitude
                    geofence.radius = 50
                    geofence.triggers = NSNumber(value: UInt32(GeofenceManager.Trigger.enter.rawValue | GeofenceManager.Trigger.enter.rawValue) as UInt32)
                    geofence.save()
                    SwiftyBeaver.self.debug("Imported \(geofence)")
                })
            }
            DispatchQueue.main.async(execute: { [weak self] in
                SwiftyBeaver.self.debug("Syncing Monitored Regions…")
                self?.geofenceManager.syncMonitoredRegions()
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
