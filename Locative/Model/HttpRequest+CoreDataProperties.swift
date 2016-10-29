import Foundation
import CoreData


extension HttpRequest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HttpRequest> {
        return NSFetchRequest<HttpRequest>(entityName: "HttpRequest");
    }

    @NSManaged public var eventType: NSNumber?
    @NSManaged public var failCount: NSNumber?
    @NSManaged public var httpAuth: NSNumber?
    @NSManaged public var httpAuthPassword: String?
    @NSManaged public var httpAuthUsername: String?
    @NSManaged public var method: String?
    @NSManaged public var parameters: NSDictionary?
    @NSManaged public var timestamp: NSDate?
    @NSManaged public var url: String?
    @NSManaged public var uuid: String?

}
