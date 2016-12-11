import AFNetworking

class HttpRequestManager: NSObject {
    static let maxFailCount = 3
    
    static let sharedManager = HttpRequestManager()
    fileprivate let queue = OperationQueue()
    
    fileprivate var currentlyFlushing = false
    fileprivate var lastRequestIds = [String]()
    
    fileprivate var appDelegate: AppDelegate {
        get {
            return UIApplication.shared.delegate as! AppDelegate
        }
    }
    
}

//MARK: - Internal
extension HttpRequestManager {
    func flushWithCompletion(_ completion: (()->())?) {
        if currentlyFlushing {
            return
        }
        currentlyFlushing = true
        
        if lastRequestIds.count > 100 {
            lastRequestIds.removeAll()
        }
        
        var operation: Operation!
        var previousOperation: Operation?
        (HttpRequest.all() as! [HttpRequest]).forEach { [weak self] req in
            guard let this = self else { return }
            guard let uuid = req.uuid else { return }
            
            // Don't retry in case failcount reaches threshold
            if let fc = req.failCount , fc.intValue < HttpRequestManager.maxFailCount && !this.lastRequestIds.contains(uuid) {
                if uuid.lengthOfBytes(using: String.Encoding.utf8) > 0 {
                    this.lastRequestIds.append(uuid)
                }
                if this.appDelegate.reachabilityManager.isReachable {
                    // Only try to send request if device is reachable via WWAN or WiFi
                    operation = BlockOperation {
                        this.dispatch(req) { success in
                            this.main {
                                guard let idx = this.lastRequestIds.index(of: uuid) else { return }
                                this.lastRequestIds.remove(at: idx)
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
        operation = BlockOperation { [weak self] in
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
    
    func dispatchFencelog(_ fencelog: Fencelog) {
        if let s = appDelegate.settings,
            let a = s.apiToken , a.lengthOfBytes(using: String.Encoding.utf8) > 0 {
            appDelegate.cloudManager.dispatchCloudFencelog(fencelog, onFinish: nil)
        }
    }
}

private extension HttpRequestManager {
    func main(_ closure:@escaping ()->Void) {
        DispatchQueue.main.async(execute: closure)
    }
}

//MARK: - Private
extension HttpRequestManager {
    func dispatch(_ request: HttpRequest, completion: @escaping (_ success: Bool)->()) {

        func handleRequest(_ req: HttpRequest, success: Bool) {
            self.main {
                if success {
                    return req.delete()
                }
                // Increase failcount on error
                // perform check for fault and returns nil if object doesn't exist anymore
                // e.g. if request has already been fulfilled/removed
                // fixes https://fabric.io/locative/ios/apps/com.marcuskida.geofancy/issues/573d92aaffcdc04250123a23
                let o = try? req.managedObjectContext?.existingObject(with: req.objectID) as! HttpRequest
                if let object = o, let fc = req.failCount {
                    object.failCount = NSNumber(value: fc.int32Value + 1 as Int32)
                    object.save()
                }
            }
        }
        
        let identifier = request.uuid ?? UUID().uuidString
        let configuration = URLSessionConfiguration.background(withIdentifier: identifier)
        let manager = AFHTTPSessionManager(sessionConfiguration: configuration)
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.requestSerializer = AFHTTPRequestSerializer()
        manager.securityPolicy = .locativePolicy
        
        if let h = request.httpAuth,
            let u = request.httpAuthUsername,
            let p = request.httpAuthPassword , h.boolValue {
            manager.requestSerializer.setAuthorizationHeaderFieldWithUsername(
                u,
                password: p
            )
        }
        
        // bail out in case no url is present in request
        guard let url = request.url else { return }
        if let m = request.method , isPostMethod(m) {
            manager.post(url, parameters: request.parameters, success: { [weak self] op, r in
                handleRequest(request, success: true)
                self?.dispatchFencelog(
                    true,
                    request: request,
                    responseObject: r as AnyObject?,
                    responseStatus: (op.response as? HTTPURLResponse)?.statusCode ?? 0,
                    error: nil, 
                    completion: completion
                )
                }, failure: { [weak self] op, e in
                    handleRequest(request, success: false)
                    self?.dispatchFencelog(
                        false,
                        request: request,
                        responseObject: nil,
                        responseStatus: (op?.response as? HTTPURLResponse)?.statusCode ?? 0,
                        error: e as NSError?,
                        completion: completion
                    )
                })
        } else {
            manager.get(url, parameters: request.parameters, success: { [weak self] op, r in
                handleRequest(request, success: true)
                self?.dispatchFencelog(
                    true,
                    request: request,
                    responseObject: r as AnyObject?,
                    responseStatus: (op.response as? HTTPURLResponse)?.statusCode ?? 0,
                    error: nil,
                    completion: completion
                )
                }, failure: { [weak self] op, e in
                    handleRequest(request, success: false)
                    self?.dispatchFencelog(
                        false,
                        request: request,
                        responseObject: nil,
                        responseStatus: (op?.response as? HTTPURLResponse)?.statusCode ?? 0,
                        error: e as NSError?,
                        completion: completion
                    )
                })
        }
    }
    
    func dispatchFencelog(_ success: Bool,
                          request: HttpRequest,
                          responseObject: AnyObject?,
                          responseStatus: Int?,
                          error: NSError?,
                          completion: @escaping (_ success: Bool)->()) {
        
        //TODO: This can be simplified a lot, DO IT!
        if let s = appDelegate.settings {
            if let method = request.method, let n = s.notifyOnSuccess , n.boolValue && success{
                // notify on success
                if let data = responseObject as? Data, let string = String(data: data, encoding: String.Encoding.utf8) {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Success:", comment: "POST Success text") : NSLocalizedString("GET Success:", comment: "GET Success text")).appendingFormat("%@", string),
                        success: true
                    )
                } else {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Success:", comment: "POST Success text") : NSLocalizedString("GET Success:", comment: "GET Success text")).appendingFormat("%@", "No readable response received."),
                        success: true
                    )
                }
            } else if let method = request.method, let n = s.notifyOnFailure , n.boolValue && !success {
                // notify on failure
                if let data = responseObject as? Data, let string = String(data: data, encoding: String.Encoding.utf8) {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Failure:", comment: "POST Failure text") : NSLocalizedString("GET Failure:", comment: "GET Failure text")).appendingFormat("%@", string),
                        success: true
                    )
                } else {
                    presentLocalNotification(
                        (isPostMethod(method) ? NSLocalizedString("POST Failure:", comment: "POST Failure text") : NSLocalizedString("GET Failure:", comment: "GET Success text")).appendingFormat("%@", "No readable response received."),
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
            fencelog.fenceType = eventType.int32Value == 0 ? "geofence" : "ibeacon"
        }

        fencelog.httpUrl = request.url
        fencelog.httpMethod = request.method
        
        if let s = responseStatus {
            fencelog.httpResponseCode = NSNumber(value: s as Int)
        }

        dispatchFencelog(fencelog)
        DispatchQueue.main.async { 
            completion(success)
        }
        
    }
    
    func presentLocalNotification(_ text: String, success: Bool) {
        UILocalNotification.present(
            withSoundName: (appDelegate.settings?.soundOnNotification?.boolValue == true) ? "notification.caf" : nil,
            alertBody: text,
            userInfo: ["success": success])
    }
    
    func isPostMethod(_ method: String) -> Bool {
        return method == "POST"
    }
}
