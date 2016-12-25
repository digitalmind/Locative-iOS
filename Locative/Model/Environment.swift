import Foundation

struct Environment {
    fileprivate static func plist(_ name: String) -> NSDictionary? {
        guard let path = Bundle.main
            .path(forResource: name, ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }
}

// MARK: - SwiftyBeaver
extension Environment {
    struct SwiftyBeaver {
        private static let plist = "SwiftyBeaver"
        static let enabled = (Environment.plist(plist) != nil)
        static let appId = Environment.plist(plist)?["SBAppId"] as? String
        static let appSecret = Environment.plist(plist)?["SBAppSecret"] as? String
        static let encryptionKey = Environment.plist(plist)?["SBEncryptionKey"] as? String
    }
}
