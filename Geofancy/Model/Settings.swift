//
//  Settings.swift
//  Locative
//
//  Created by Marcus Kida on 27/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import Foundation

class Settings: NSObject, NSCoding {

    var globalUrl: NSURL?
    var appHasBeenStarted = false
    var globalHttpMethod = 0
    var notifyOnSuccess = true
    var notifyOnFailure = true
    var soundOnNotification = true
    var httpBasicAuthEnabled = false
    var httpBasicAuthUsername: String?
    var httpBasicAuthPassword: String?
    
    let cloudSession = "cloudSession"
    
    let basicAuthCredentials = SecureCredentials(service: "GlobalBasicAuth")
    let apiCredentials = SecureCredentials(service: "ApiToken")
    
    var apiToken: String? {
        get {
            self.migrateApiToken()
            if let old = old_apiToken() where old.characters.count > 0 {
                self.apiCredentials[cloudSession] = old
                self.old_removeApiToken()
            }
            return self.apiCredentials[cloudSession]
        }
        
        set {
            guard let new = newValue else {
                return removeApiToken()
            }
            if let old = old_apiToken() where old.characters.count > 0 {
                defaults().removeObjectForKey(cloudSession)
                defaults().synchronize()
            }
            self.apiCredentials[cloudSession] = new
            self.setApiTokenForContainer(new)
        }
    }

    private func defaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        globalUrl = aDecoder.decodeObjectForKey("globalUrl") as? NSURL
        appHasBeenStarted = aDecoder.decodeBoolForKey("appHasBeenStarted")
        globalHttpMethod = aDecoder.decodeIntegerForKey("globalHttpMethod")
        notifyOnSuccess = aDecoder.decodeBoolForKey("notifyOnSuccess")
        notifyOnFailure = aDecoder.decodeBoolForKey("notifyOnFailure")
        soundOnNotification = aDecoder.decodeBoolForKey("soundOnNotification")
        httpBasicAuthEnabled = aDecoder.decodeBoolForKey("httpBasicAuthEnabled")
        httpBasicAuthUsername = aDecoder.decodeObjectForKey("httpBasicAuthUsername") as? String
        httpBasicAuthPassword = aDecoder.decodeObjectForKey("httpBasicAuthPassword") as? String
        
        guard let httpBasicAuthUsername = httpBasicAuthUsername else { return }
        
        if httpBasicAuthUsername.isNotEmpty() {
            self.basicAuthCredentials[httpBasicAuthUsername] = httpBasicAuthPassword
        }
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(globalUrl, forKey: "globalUrl")
        aCoder.encodeBool(appHasBeenStarted, forKey: "appHasBeenStarted")
        aCoder.encodeInteger(globalHttpMethod, forKey: "globalHttpMethod")
        aCoder.encodeBool(notifyOnSuccess, forKey: "notifyOnSuccess")
        aCoder.encodeBool(notifyOnFailure, forKey: "notifyOnFailure")
        aCoder.encodeBool(soundOnNotification, forKey: "soundOnNotification")
        aCoder.encodeBool(httpBasicAuthEnabled, forKey: "httpBasicAuthEnabled")
        aCoder.encodeObject(httpBasicAuthUsername, forKey: "httpBasicAuthUsername")
        aCoder.encodeObject(nil, forKey: "httpBasicAuthPassword")
        
        guard let httpBasicAuthUsername = httpBasicAuthUsername else { return }
        
        httpBasicAuthPassword = basicAuthCredentials[httpBasicAuthUsername]
    }
    
}

//MARK: - Restoration
extension Settings {
    func restoredSettings() -> Settings? {
        if let oldSettingsPath = NSString.oldSettingsPath(),
            newSettingsPath = NSString.settingsPath() {
            if NSFileManager.defaultManager().fileExistsAtPath(oldSettingsPath) {
                try! NSFileManager.defaultManager().moveItemAtPath(oldSettingsPath, toPath: newSettingsPath)
            }
        }
        guard let new = NSString.settingsPath() else {
            return nil
        }
        guard let restored = NSKeyedUnarchiver.unarchiveObjectWithFile(new) as? Settings else {
            return Settings()
        }
        return restored
    }
}

//MARK: - API Token
extension Settings {
    //MARK: - Legacy
    func old_apiToken() -> String? {
        return defaults().stringForKey(cloudSession)
    }
    
    func old_removeApiToken() {
        defaults().removeObjectForKey(cloudSession)
        defaults().synchronize()
    }
    
    //MARK: - Removal
    func removeApiToken() {
        apiCredentials[cloudSession] = nil
        removeApiTokenFromContainer()
    }
    
    private func migrateApiToken() {
        if let old = old_apiToken() where !old.isEmpty {
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
    func setApiTokenForContainer(apiToken: String) {
        NSUserDefaults.sharedSuite()?.setObject(apiToken, forKey: "sessionId")
        NSUserDefaults.sharedSuite()?.synchronize()
    }
    
    func removeApiTokenFromContainer() {
        NSUserDefaults.sharedSuite()?.removeObjectForKey("sessionId")
        NSUserDefaults.sharedSuite()?.synchronize()
    }
}