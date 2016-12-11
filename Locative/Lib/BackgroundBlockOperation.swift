import Foundation

open class BackgroundBlockOperation: BlockOperation {
    var automaticallyEndsBackgroundTask = true
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    func startBackgroundTask() {
        qualityOfService = .background
        backgroundTaskIdentifier = UIApplication.shared
            .beginBackgroundTask (expirationHandler: { [weak self] in
                self?.endBackgroundTask()
        })
    }
    
    func endBackgroundTask() {
        if let identifier = backgroundTaskIdentifier ,
            identifier != UIBackgroundTaskInvalid {
            UIApplication.shared.endBackgroundTask(identifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
    }
    
    override open func addExecutionBlock(_ block: @escaping ()->()) {
        super.addExecutionBlock { [weak self] in
            self?.startBackgroundTask()
            block()
            if let this = self , this.automaticallyEndsBackgroundTask {
                self?.endBackgroundTask()
            }
        }
    }
}
