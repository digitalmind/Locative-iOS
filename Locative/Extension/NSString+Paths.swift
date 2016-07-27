import Foundation

extension NSString {
    class func documentsDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
    }
    
    class func oldSettingsPath() -> String? {
        return documentsDirectory()?.stringByAppendingString("/settings.plist")
    }
    
    class func settingsPath() -> String? {
        return documentsDirectory()?.stringByAppendingString("/.settings.plist")
    }
}