import Foundation

private extension String {
    static let apnsToken = "apnsToken"
    static let accountData = "accountData"
}

class Settings: NSObject, NSCoding {

    @objc var globalUrl: URL?
    var appHasBeenStarted: NSNumber? = NSNumber(value: false as Bool)
    @objc var globalHttpMethod: NSNumber? = NSNumber(value: 0 as Int)
    var notifyOnSuccess: NSNumber? = NSNumber(value: true as Bool)
    var notifyOnFailure: NSNumber? = NSNumber(value: true as Bool)
    var soundOnNotification: NSNumber? = NSNumber(value: true as Bool)
    var httpBasicAuthEnabled: NSNumber? = NSNumber(value: false as Bool)
    var httpBasicAuthUsername: String?
    var httpBasicAuthPassword: String?
    var debugEnabled: NSNumber = NSNumber(value: false as Bool)
    var overrideTriggerThreshold: NSNumber = NSNumber(booleanLiteral: true)
    
    let cloudSession = "cloudSession"
    
    let basicAuthCredentials = SecureCredentials(service: "GlobalBasicAuth")
    let apiCredentials = SecureCredentials(service: "ApiToken")
    
    @objc var apiToken: String? {
        get {
            self.migrateApiToken()
            if let old = old_apiToken() , old.characters.count > 0 {
                self.apiCredentials[cloudSession] = old
                self.old_removeApiToken()
            }
            return self.apiCredentials[cloudSession]
        }
        
        set {
            guard let new = newValue else {
                return removeApiToken()
            }
            if let old = old_apiToken() , old.characters.count > 0 {
                defaults().removeObject(forKey: cloudSession)
                defaults().synchronize()
            }
            self.apiCredentials[cloudSession] = new
            self.setApiTokenForContainer(new)
        }
    }
    
    var accountData: CloudConnect.AccountData? {
        get {
            guard let accountData = defaults().object(forKey: .accountData) as? [String: String] else {
                return nil
            }
            return CloudConnect.AccountData(
                username: accountData["username"] ?? "Unknown".localized(),
                email: accountData["email"] ?? "Unknown".localized(),
                avatarUrl: accountData["awaterUrl"] ?? ""
            )
        }
        set {
            guard let new = newValue else {
                return defaults().removeObject(forKey: .accountData)
            }
            defaults().set(new.toPlist(), forKey: .accountData)
            defaults().synchronize()
        }
    }
    
    var isLoggedIn: Bool {
        get {
            guard let token = apiToken else {
                return false
            }
            return token.isNotEmpty()
        }
    }
    
   @objc var apnsToken: String? {
        get {
            return defaults().string(forKey: .apnsToken)
        }
        set {
            defaults().set(newValue, forKey: .apnsToken)
            defaults().synchronize()
        }
    }
    
    fileprivate func defaults() -> UserDefaults {
        return UserDefaults.standard
    }
    
    override init() {
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        globalUrl = aDecoder.decodeObject(forKey: "globalUrl") as? URL
        appHasBeenStarted = aDecoder.decodeObject(forKey: "appHasBeenStarted") as? NSNumber
        globalHttpMethod = aDecoder.decodeObject(forKey: "globalHttpMethod") as? NSNumber
        notifyOnSuccess = aDecoder.decodeObject(forKey: "notifyOnSuccess") as? NSNumber
        notifyOnFailure = aDecoder.decodeObject(forKey: "notifyOnFailure") as? NSNumber
        soundOnNotification = aDecoder.decodeObject(forKey: "soundOnNotification") as? NSNumber
        httpBasicAuthEnabled = aDecoder.decodeObject(forKey: "httpBasicAuthEnabled") as? NSNumber
        httpBasicAuthUsername = aDecoder.decodeObject(forKey: "httpBasicAuthUsername") as? String
        httpBasicAuthPassword = aDecoder.decodeObject(forKey: "httpBasicAuthPassword") as? String
        debugEnabled = aDecoder.decodeObject(forKey: "debugEnabled") as? NSNumber ?? NSNumber(booleanLiteral: false)
        overrideTriggerThreshold = aDecoder.decodeObject(forKey: "overrideTriggerThreshold") as? NSNumber ?? NSNumber(booleanLiteral: true)
        guard let httpBasicAuthUsername = httpBasicAuthUsername else { return }
        
        if httpBasicAuthUsername.isNotEmpty() {
            if httpBasicAuthPassword == nil {
                httpBasicAuthPassword = self.basicAuthCredentials[httpBasicAuthUsername]
            } else {
                self.basicAuthCredentials[httpBasicAuthUsername] = httpBasicAuthPassword
            }
        }
        
    }
    
    open func encode(with aCoder: NSCoder) {
        aCoder.encode(globalUrl, forKey: "globalUrl")
        aCoder.encode(appHasBeenStarted, forKey: "appHasBeenStarted")
        aCoder.encode(globalHttpMethod, forKey: "globalHttpMethod")
        aCoder.encode(notifyOnSuccess, forKey: "notifyOnSuccess")
        aCoder.encode(notifyOnFailure, forKey: "notifyOnFailure")
        aCoder.encode(soundOnNotification, forKey: "soundOnNotification")
        aCoder.encode(httpBasicAuthEnabled, forKey: "httpBasicAuthEnabled")
        aCoder.encode(httpBasicAuthUsername, forKey: "httpBasicAuthUsername")
        aCoder.encode(nil, forKey: "httpBasicAuthPassword")
        aCoder.encode(debugEnabled, forKey: "debugEnabled")
        aCoder.encode(overrideTriggerThreshold, forKey: "overrideTriggerThreshold")
        
        guard let httpBasicAuthUsername = httpBasicAuthUsername else { return }
        guard let httpBasicAuthPassword = httpBasicAuthPassword else { return }
        
        basicAuthCredentials[httpBasicAuthUsername] = httpBasicAuthPassword
    }
    
    func toggleDebug() {
        debugEnabled = NSNumber(booleanLiteral: !debugEnabled.boolValue)
        self.persist()
    }
    
}

//MARK: - Restoration
extension Settings {
    @objc public func restoredSettings() -> Settings {
        if let oldSettingsPath = NSString.oldSettingsPath(),
            let newSettingsPath = NSString.settingsPath() {
            if FileManager.default.fileExists(atPath: oldSettingsPath) {
                try! FileManager.default.moveItem(atPath: oldSettingsPath, toPath: newSettingsPath)
            }
        }
        guard let new = NSString.settingsPath() else {
            return Settings()
        }
        // important: otherwise we can't restore from original settings
        NSKeyedUnarchiver.setClass(type(of: self), forClassName: "GFSettings")
        // in case we don't have any setttings, let's just return a fresh settings instance
        guard let restored = NSKeyedUnarchiver.unarchiveObject(withFile: new) as? Settings else {
            return Settings()
        }
        return restored
    }
}

//MARK: - API Token
extension Settings {
    
    //MARK: - Legacy
    func old_apiToken() -> String? {
        return defaults().string(forKey: cloudSession)
    }
    
    func old_removeApiToken() {
        defaults().removeObject(forKey: cloudSession)
        defaults().synchronize()
    }
    
    //MARK: - Removal
    @objc func removeApiToken() {
        apiCredentials[cloudSession] = nil
        removeApiTokenFromContainer()
    }
    
    func removeAccountData() {
        defaults().removeObject(forKey: .accountData)
        defaults().synchronize()
    }
    
    fileprivate func migrateApiToken() {
        if let old = old_apiToken() , !old.isEmpty {
            apiToken = old
            old_removeApiToken()
        }
    }
    
    //MARK: - Persitency
    func persist() {
        guard let newSettingsPath = NSString.settingsPath() else {
            return assertionFailure()
        }
        NSKeyedArchiver.archiveRootObject(self, toFile: newSettingsPath)
    }
    
    //MARK: - Shared suite
    func setApiTokenForContainer(_ apiToken: String) {
        UserDefaults.sharedSuite()?.set(apiToken, forKey: "sessionId")
        UserDefaults.sharedSuite()?.synchronize()
    }
    
    func removeApiTokenFromContainer() {
        UserDefaults.sharedSuite()?.removeObject(forKey: "sessionId")
        UserDefaults.sharedSuite()?.synchronize()
    }
}
