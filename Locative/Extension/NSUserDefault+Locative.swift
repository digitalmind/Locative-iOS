import Foundation

extension UserDefaults {
    static func sharedSuite() -> UserDefaults? {
        return UserDefaults(suiteName: "group.marcuskida.Geofancy")
    }
}
