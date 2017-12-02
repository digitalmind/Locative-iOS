import CoreLocation
import ObjectiveRecord
import SwiftyBeaver

public typealias OnLocationUpdated = ((CLLocation?) -> Void)

class GeofenceManager: NSObject, CLLocationManagerDelegate {
    
    @objc enum Trigger: Int {
        case
        enter = 0b1,
        exit = 0b10
    }
    
    let settings: Settings
    let requestManager: HttpRequestManager
    let locationManager = CLLocationManager()
    
    var geofences: [Geofence] {
        return (Geofence.all() as! [Geofence])
    }
    
    var onLocation: OnLocationUpdated?
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    internal var onCurrentLocation: OnLocationUpdated?
    
    init(settings: Settings, requestManager: HttpRequestManager) {
        self.settings = settings
        self.requestManager = requestManager
        super.init()
        locationManager.delegate = self
        authorize()
        startMonitoring()
        syncMonitoredRegions()
    }
    
    private func authorize() {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    private func startMonitoring() {
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    func triggerLocationEvent(_ manager: CLLocationManager, trigger: Trigger, region: CLRegion) {
        guard let location = geofences.filter({ region.identifier == $0.uuid }).first else {
            return syncMonitoredRegions()
        }
        
        // Do nothing in case we don't want to trigger an enter event
        if trigger == .enter && (location.triggers!.uintValue & UInt(Trigger.enter.rawValue) == 0) {
            return
        }
        // Do nothing in case we don't want to trigger an exit event
        if trigger == .exit && (location.triggers!.uintValue & UInt(Trigger.exit.rawValue) == 0) {
            return
        }
        
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        let locationUrl = (trigger == .enter ? location.enterUrl : location.exitUrl) ?? settings.globalUrl?.absoluteString
        
        var id = location.uuid!
        if let customId = location.customId, !customId.isEmpty {
            id = customId
        }
        
        let deviceId = UIDevice.current.identifierForVendor!.uuidString
        let timestamp = NSDate()
        
        let parameters = [
            "id": id,
            "trigger": trigger == .enter ? "enter" : "exit",
            "device": deviceId,
            "device_type": "iOS",
            "device_model": UIDevice.locative_deviceModel(),
            "latitude": location.latitude?.doubleValue ?? 0.0,
            "longitude": location.longitude?.doubleValue ?? 0.0,
            "timestamp": timestamp.timeIntervalSince1970
        ] as NSDictionary
        
        if let url = locationUrl, !url.isEmpty {
            // Got an URL, let's try to dispatch to it
            let request = HttpRequest()
            request.url = url
            request.method = {
                return ((trigger == .enter ? location.enterMethod! : location.exitMethod!)).intValue == 0 ? "POST": "GET"
            }()
            request.parameters = parameters
            request.eventType = location.type
            request.timestamp = timestamp
            request.uuid = location.uuid
            request.eventId = location.readableId()
            
            if let auth = location.httpAuth, auth.boolValue {
                // Authenticate using Events HTTP credentials
                request.httpAuth = NSNumber(booleanLiteral: true)
                request.httpAuthUsername = location.httpUser
                request.httpAuthPassword = location.httpPasswordSecure
            } else if let auth = settings.httpBasicAuthEnabled, auth.boolValue {
                request.httpAuth = NSNumber(booleanLiteral: true)
                request.httpAuthUsername = settings.httpBasicAuthUsername
                request.httpAuthPassword = settings.httpBasicAuthPassword
            }
            requestManager.dispatch(request)
        } else {
            // Got an empty URL, only sending Fencelog
            let notificationString = trigger == .enter ? NSLocalizedString("entered", comment: "Fencelog notification entered") : NSLocalizedString("left", comment: "Fencelog notification left")
            let fencelog = Fencelog()
            fencelog.locationId = id
            fencelog.latitude = location.latitude ?? 0.0
            fencelog.longitude = location.longitude ?? 0.0
            fencelog.eventType = trigger == .enter ? "enter" : "exit"
            fencelog.fenceType = location.type!.intValue == 0 ? "geofence" : "ibeacon"
            requestManager.dispatchFencelog(fencelog)
            if let notify = settings.notifyOnSuccess, notify.boolValue {
                requestManager.presentLocalNotification(
                    NSString(format:
                        NSString(string: NSLocalizedString("%@ has been %@.", comment: "Fencelog-only notification string")), id, notificationString
                    ) as String,
                    success: true
                )
            }
        }
    }
    
    private func startMonitoring(event: Geofence) {
        if event.type!.intValue == GeofenceType.geofence.rawValue {
            // Geofence / CircularRegion
            let region = CLCircularRegion(
                center: CLLocationCoordinate2DMake(event.latitude!.doubleValue, event.longitude!.doubleValue),
                radius: event.radius!.doubleValue,
                identifier: event.uuid!
            )
            locationManager.startMonitoring(for: region)
        } else {
            // iBeacon
            guard let uuidString = event.uuid, let uuid = UUID(uuidString: uuidString) else {
                return SwiftyBeaver.self.error("Could not start monitoring of CLBeaconRegion because of missing / invalid UUID")
            }
            guard let major = event.iBeaconMajor, let minor =
                event.iBeaconMinor else {
                return locationManager.startMonitoring(for:
                    CLBeaconRegion(proximityUUID: uuid, identifier: uuidString)
                )
            }
            locationManager.startMonitoring(for:
                CLBeaconRegion(
                    proximityUUID: uuid,
                    major: CLBeaconMajorValue(major.intValue),
                    minor: CLBeaconMinorValue(minor.intValue),
                    identifier: uuidString
                )
            )
        }
    }
    
    @objc func syncMonitoredRegions() {
        // stop monitoring for all regions regions
        locationManager.monitoredRegions.forEach { region in
            SwiftyBeaver.self.debug("Stopping region \(region)")
            locationManager.stopMonitoring(for: region)
        }
        
        // start monitoring for all existing regions
        geofences.forEach { geofence in
            SwiftyBeaver.self.debug("Starting geofence \(geofence)")
            startMonitoring(event: geofence)
        }
    }
    
    @objc func performAfterRetrievingCurrentLocation(completion: @escaping OnLocationUpdated) {
        onCurrentLocation = completion
        locationManager.startUpdatingLocation()
    }
    
}

// MARK: CLLocationManagerDelegate
extension GeofenceManager {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .denied {
            onLocation?(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        SwiftyBeaver.self.debug("didUpdateLocations: \(locations)")
        onLocation?(locations.first)
        onCurrentLocation?(locations.first)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        triggerLocationEvent(manager, trigger: .enter, region: region)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        triggerLocationEvent(manager, trigger: .exit, region: region)
    }
}

// MARK: BackgroundTask
extension GeofenceManager {
    func endBackgroundTask() {
        if backgroundTask != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(backgroundTask!)
            backgroundTask = UIBackgroundTaskInvalid
        }
    }
}
