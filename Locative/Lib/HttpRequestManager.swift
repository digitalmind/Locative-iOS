import AFNetworking
import SwiftyBeaver

class HttpRequestManager: NSObject {
    static let sharedManager = HttpRequestManager()
    private let queue = NSOperationQueue()
    
    private var currentlyFlushing = false
    private var lastRequestIds = [String]()
    
    private var appDelegate: AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as! AppDelegate
        }
    }
    
}

//MARK: - Internal
extension HttpRequestManager {
    func flushWithCompletion(completion: (()->())?) {
        if currentlyFlushing {
            return
        }
        currentlyFlushing = true
        
        if lastRequestIds.count > 100 {
            lastRequestIds.removeAll()
        }
        
        var operation: NSOperation!
        var previousOperation: NSOperation?
        (HttpRequest.all() as! [HttpRequest]).forEach { [weak self] req in
            guard let this = self else { return }
            guard let uuid = req.uuid else { return }
            if let fc = req.failCount where fc.intValue >= 3 || this.lastRequestIds.contains(uuid) {
                // Delete request in case failCount reaches 3
                req.delete()
            } else {
                if uuid.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                    this.lastRequestIds.append(uuid)

                }
                if this.appDelegate.reachabilityManager.reachable {
                    // Only try to send request if device is reachable via WWAN or WiFi
                    operation = NSBlockOperation {
                        this.dispatch(req) { success in
                            if success {
                                return req.delete()
                            }
                            // Increase failcount on error
                            // perform check for fault and returns nil if object doesn't exist anymore
                            // e.g. if request has already been fulfilled/removed
                            // fixes https://fabric.io/locative/ios/apps/com.marcuskida.geofancy/issues/573d92aaffcdc04250123a23
                            let o = try? req.managedObjectContext?.existingObjectWithID(req.objectID) as! HttpRequest
                            if let object = o, fc = req.failCount {
                                object.failCount = NSNumber(int: fc.intValue + 1)
                            }
                            
                        }
                    }
                    if let p = previousOperation {
                        operation.addDependency(p)
                    }
                    previousOperation = operation
                    this.queue.addOperation(operation)
                }
            }
        }
        operation = NSBlockOperation { [weak self] in
            self?.currentlyFlushing = false
            if let cb = completion {
                cb()
            }
        }
        if let p = previousOperation {
            operation.addDependency(p)
        }
        queue.addOperation(operation)
    }
    
    func dispatchFencelog(fencelog: Fencelog) {
        if let s = appDelegate.settings,
            a = s.apiToken where a.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
            appDelegate.cloudManager.dispatchCloudFencelog(fencelog, onFinish: nil)
        }
    }
}

//MARK: - Private
private extension HttpRequestManager {
    func dispatch(request: HttpRequest, completion: (success: Bool)->()) {

        let manager = AFHTTPRequestOperationManager()
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.securityPolicy = commonPolicy()
        
        if let h = request.httpAuth,
            u = request.httpAuthUsername,
            p = request.httpAuthPassword where h.boolValue {
            manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(
                u,
                password: p
            )
        }
        
        if let url = request.url {
            if let m = request.method where isPostMethod(m) {
                manager.POST(url, parameters: request.parameters, success: { [weak self] op, r in
                    SwiftyBeaver.debug("HTTP request completion: \(r)")
                    self?.dispatchFencelog(
                        true,
                        request: request,
                        responseObject: r,
                        responseStatus: op.response?.statusCode,
                        error: nil,
                        completion: completion
                    )
                    }, failure: { [weak self] op, e in
                        self?.dispatchFencelog(
                            false,
                            request: request,
                            responseObject: nil,
                            responseStatus: op?.response?.statusCode,
                            error: e,
                            completion: completion
                        )
                    })
            } else {
                manager.GET(url, parameters: request.parameters, success: { [weak self] op, r in
                    SwiftyBeaver.debug("HTTP request completion: \(r)")
                    self?.dispatchFencelog(
                        true,
                        request: request,
                        responseObject: r,
                        responseStatus: op.response?.statusCode,
                        error: nil,
                        completion: completion
                    )
                    }, failure: { [weak self] op, e in
                        self?.dispatchFencelog(
                            false,
                            request: request,
                            responseObject: nil,
                            responseStatus: op?.response?.statusCode,
                            error: e,
                            completion: completion
                        )
                    })
            }
        }
    }
    
    func dispatchFencelog(success: Bool,
                          request: HttpRequest,
                          responseObject: AnyObject?,
                          responseStatus: Int?,
                          error: NSError?,
                          completion: (success: Bool)->()) {
        
        //TODO: This can be simplified a lot, DO IT!
        if let s = appDelegate.settings {
            if let method = request.method, n = s.notifyOnSuccess where n.boolValue && success{
                // notify on success
                if let data = responseObject as? NSData, string = String(data: data, encoding: NSUTF8StringEncoding) {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Success:", comment: "POST Success text") : NSLocalizedString("GET Success:", comment: "GET Success text")).stringByAppendingFormat("%@", string),
                        success: true
                    )
                } else {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Success:", comment: "POST Success text") : NSLocalizedString("GET Success:", comment: "GET Success text")).stringByAppendingFormat("%@", "No readable response received."),
                        success: true
                    )
                }
            } else if let method = request.method, n = s.notifyOnFailure where n.boolValue && !success {
                // notify on failure
                if let data = responseObject as? NSData, string = String(data: data, encoding: NSUTF8StringEncoding) {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Failure:", comment: "POST Failure text") : NSLocalizedString("GET Failure:", comment: "GET Failure text")).stringByAppendingFormat("%@", string),
                        success: true
                    )
                } else {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Failure:", comment: "POST Failure text") : NSLocalizedString("GET Failure:", comment: "GET Success text")).stringByAppendingFormat("%@", "No readable response received."),
                        success: true
                    )
                }
            }
        }
        
        // dispatch fencelog
        let fencelog = Fencelog()
        
        if let parameters = request.parameters {
            
            if let l = parameters["latitude"] as? NSNumber {
                fencelog.latitude = l
            }
            if let l = parameters["longitude"] as? NSNumber {
                fencelog.longitude = l
            }
            if let i = parameters["id"] as? String {
                fencelog.locationId = i
            }
            fencelog.eventType = parameters["trigger"] as? String
        }
        
        if let eventType = request.eventType {
            fencelog.fenceType = eventType.intValue == 0 ? "geofence" : "ibeacon"
        }

        fencelog.httpUrl = request.url
        fencelog.httpMethod = request.method
        
        if let s = responseStatus {
            fencelog.httpResponseCode = NSNumber(long: s)
        }
        if let r = responseObject as? NSData {
            fencelog.httpResponse = String(data: r, encoding: NSUTF8StringEncoding)
        } else {
            fencelog.httpResponse = "<See error code>"
        }
        
        dispatchFencelog(fencelog)
        dispatch_async(dispatch_get_main_queue()) { 
            completion(success: success)
        }
        
    }
    
    func presentLocalNotification(text: String, success: Bool) {
        //TODO: this is rediculously complicated... FIX IT
        var sound: String? = "notification.caf"
        if let s = appDelegate.settings?.soundOnNotification where s.boolValue == false {
            sound = nil
        }

        UILocalNotification.presentLocalNotificationWithSoundName(
            sound,
            alertBody: text,
            userInfo: ["success": success])
    }
    
    func commonPolicy() -> AFSecurityPolicy {
        let policy = AFSecurityPolicy(pinningMode: .None)
        policy.allowInvalidCertificates = true
        policy.validatesDomainName = false
        return policy
    }
    
    func isPostMethod(method: String) -> Bool {
        return method == "POST"
    }
}