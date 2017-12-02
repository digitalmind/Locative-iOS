import Foundation
import ObjectiveRecord

@objc enum GeofenceType: Int {
    case geofence = 0, iBeacon = 1
}

fileprivate extension TimeInterval {
    static let geolocationTriggerThreshold = 30
}

extension Geofence {
    @objc public var httpPasswordSecure: String? {
        set {
            guard let httpUser = httpUser else { return }
            guard let uuid = uuid else { return }
            SecureCredentials(service: uuid)[httpUser] = newValue
        }
        get {
            guard let httpUser = httpUser else { return nil }
            guard let uuid = uuid else { return nil }
            return SecureCredentials(service: uuid)[httpUser]
        }
    }
    
    @objc class func showMaximumGeofencesReached(alert: Bool, viewController: UIViewController) -> Bool {
        guard Geofence.all().count >= 20 else {
            return false
        }
        let alert = UIAlertController(
            title: NSLocalizedString("Note", comment: "Note"),
            message: NSLocalizedString("There's a maximum limit of 20 Geofences per App, please remove some Geofences before adding new ones.", comment: ""),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
        viewController.present(alert, animated: true, completion: nil)
        return true
    }
    
    func isGeofence() -> Bool {
        return type?.intValue == 0
    }
    
    func readableId() -> String? {
        if let id = customId, !id.isEmpty {
            return id
        }
        if let uuid = uuid, !uuid.isEmpty {
            return uuid
        }
        return nil
    }

}
