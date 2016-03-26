//
//  SecureCredentials.swift
//  Locative
//
//  Created by Marcus Kida on 26/03/2016.
//  Copyright © 2016 Marcus Kida. All rights reserved.
//

import UIKit
import KeychainAccess

class SecureCredentials: NSObject {
    
    let keychain = Keychain(service: UIApplication.bundleIdentifier()).accessibility(.AfterFirstUnlock)
    
    subscript(key: String) -> String? {
        get {
            return keychain[key]
        }
        set {
            keychain[key] = newValue
        }
    }
}
