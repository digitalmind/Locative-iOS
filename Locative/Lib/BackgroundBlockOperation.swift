import Foundation

public class BackgroundBlockOperation: NSBlockOperation {
    var automaticallyEndsBackgroundTask = true
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    func startBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.sharedApplication()
            .beginBackgroundTaskWithExpirationHandler { [weak self] in
                self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if let identifier = backgroundTaskIdentifier where
            identifier != UIBackgroundTaskInvalid {
            UIApplication.sharedApplication().endBackgroundTask(identifier)
            backgroundTaskIdentifier = UIBackgroundTaskInvalid
        }
    }
    
    override public func addExecutionBlock(block: ()->()) {
        super.addExecutionBlock { [weak self] in
            self?.startBackgroundTask()
            block()
            if let this = self where this.automaticallyEndsBackgroundTask {
                self?.endBackgroundTask()
            }
        }
    }
}
