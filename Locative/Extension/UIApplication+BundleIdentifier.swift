import UIKit

extension UIApplication {
    static func bundleIdentifier() -> String {
        guard let infoDict = Bundle.main.infoDictionary else {
            return "com.unknown"
        }
        return infoDict["CFBundleIdentifier"] as! String
    }
}
