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
    
    let oldSettingsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first?.stringByAppendingString("settings.plist")
    
    let newSettingsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first?.stringByAppendingString(".settings.plist")

    let cloudSession = "cloudSession"
    
    let basicAuthCredentials = SecureCredentials(service: "GlobalBasicAuth")
    let apiCredentials = SecureCredentials(service: "ApiToken")
    
    let defaultsContainer = NSUserDefaults(suiteName: "group.marcuskida.Geofancy")
    
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
    
    private func filemanager() -> NSFileManager {
        return NSFileManager.defaultManager()
    }
    
    private func defaults() -> NSUserDefaults {
        return NSUserDefaults.standardUserDefaults()
    }
    
    override init() {
        super.init()
        if let oldSettingsPath = oldSettingsPath,
            newSettingsPath = newSettingsPath {
        if filemanager().fileExistsAtPath(oldSettingsPath) {
            try! filemanager().moveItemAtPath(oldSettingsPath, toPath: newSettingsPath)
        }
        }
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
    
    func persist() {
        guard let newSettingsPath = newSettingsPath else {
            return assertionFailure()
        }
        NSKeyedArchiver.archiveRootObject(self, toFile: newSettingsPath)
    }
    
    func setApiTokenForContainer(apiToken: String) {
        defaultsContainer?.setObject(apiToken, forKey: "sessionId")
        defaultsContainer?.synchronize()
    }
    
    func removeApiTokenFromContainer() {
        defaultsContainer?.removeObjectForKey("sessionId")
        defaultsContainer?.synchronize()
    }
}

extension Settings {
    // legacy
    func old_apiToken() -> String? {
        return defaults().stringForKey(cloudSession)
    }
    
    func old_removeApiToken() {
        defaults().removeObjectForKey(cloudSession)
        defaults().synchronize()
    }
}