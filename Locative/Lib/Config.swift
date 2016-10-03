import Foundation

open class Config: NSObject {
    
    fileprivate let lastMessageFetchKey = "lastMessageFetch"
    fileprivate let defaults = UserDefaults.standard
    fileprivate let bundle = Bundle.main
    
    var lastMessageFetch: Date? {
        get {
            return defaults.object(forKey: lastMessageFetchKey) as? Date
        }
        set {
            defaults
                .setObject(newValue as AnyObject?, key: lastMessageFetchKey)
                .synchronize()
        }
    }
    var readableVersionString: String {
        get {
            let version = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String)
            return "\(NSLocalizedString("Version", comment: "Version string")) \(version)"
        }
    }
}

private extension UserDefaults {
    func setBool(_ value: Bool, key: String) -> UserDefaults {
        self.set(value, forKey: key)
        return self
    }
    
    func setObject(_ value: AnyObject?, key: String) -> UserDefaults {
        self.set(value, forKey: key)
        return self
    }
}

