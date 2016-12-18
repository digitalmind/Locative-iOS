import Foundation
import CoreData


class HttpRequest: NSObject {

    public var eventType: NSNumber?
    public var failCount: NSNumber?
    public var httpAuth: NSNumber?
    public var httpAuthPassword: String?
    public var httpAuthUsername: String?
    public var method: String?
    public var parameters: NSDictionary?
    public var timestamp: NSDate?
    public var url: String?
    public var uuid: String?
    public var eventId: String?
    
}
