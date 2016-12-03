import Foundation
import CoreData


extension Geofence {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Geofence> {
        return NSFetchRequest<Geofence>(entityName: "Geofence");
    }

    @NSManaged public var customId: String?
    @NSManaged public var enterMethod: NSNumber?
    @NSManaged public var enterUrl: String?
    @NSManaged public var exitMethod: NSNumber?
    @NSManaged public var exitUrl: String?
    @NSManaged public var httpAuth: NSNumber?
    @NSManaged public var httpPassword: String?
    @NSManaged public var httpUser: String?
    @NSManaged public var iBeaconMajor: NSNumber?
    @NSManaged public var iBeaconMinor: NSNumber?
    @NSManaged public var iBeaconUuid: String?
    @NSManaged public var latitude: NSNumber?
    @NSManaged public var longitude: NSNumber?
    @NSManaged public var name: String?
    @NSManaged public var radius: NSNumber?
    @NSManaged public var triggers: NSNumber?
    @NSManaged public var type: NSNumber?
    @NSManaged public var uuid: String?
    @NSManaged public var triggeredAt: Date?

}
