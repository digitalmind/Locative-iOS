import Foundation

extension NSString {
    class func documentsDirectory() -> String? {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
    }
    
    class func oldSettingsPath() -> String? {
        return (documentsDirectory())! + "/settings.plist"
    }
    
    class func settingsPath() -> String? {
        return (documentsDirectory())! + "/.settings.plist"
    }
}
