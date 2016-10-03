import UIKit
import KeychainAccess

class SecureCredentials: NSObject {
    
    var service: String { get { return keychain.service } }
    let keychain: Keychain
    
    required init(service: String) {
        keychain = Keychain(service: "\(UIApplication.bundleIdentifier()).\(service)")
            .accessibility(.afterFirstUnlock)
            .synchronizable(true)
        super.init()
    }
    
    subscript(key: String) -> String? {
        get {
            return keychain[key]
        }
        set {
            keychain[key] = newValue
        }
    }
}
