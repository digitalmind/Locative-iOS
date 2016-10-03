import Foundation

public func synchronized(_ lock: AnyObject, closure: ()->()) {
    objc_sync_enter(lock)
    closure();
    objc_sync_exit(lock)
}
