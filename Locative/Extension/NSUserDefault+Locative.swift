import Foundation

extension NSUserDefaults {
    static func sharedSuite() -> NSUserDefaults? {
        return NSUserDefaults(suiteName: "group.marcuskida.Geofancy")
    }
}