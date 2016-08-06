import Foundation

public class Config: NSObject {
    
    private let lastMessageFetchKey = "lastMessageFetch"
    private let defaults = NSUserDefaults.standardUserDefaults()
    private let bundle = NSBundle.mainBundle()
    
    var lastMessageFetch: NSDate? {
        get {
            return defaults.objectForKey(lastMessageFetchKey) as? NSDate
        }
        set {
            defaults
                .setObject(newValue, key: lastMessageFetchKey)
                .synchronize()
        }
    }
    var readableVersionString: String {
        get {
            let version = bundle.objectForInfoDictionaryKey(kCFBundleVersionKey as String)
            return "\(NSLocalizedString("Version", comment: "Version string")) \(version)"
        }
    }
}

private extension NSUserDefaults {
    func setBool(value: Bool, key: String) -> NSUserDefaults {
        self.setBool(value, forKey: key)
        return self
    }
    
    func setObject(value: AnyObject?, key: String) -> NSUserDefaults {
        self.setObject(value, forKey: key)
        return self
    }
}

