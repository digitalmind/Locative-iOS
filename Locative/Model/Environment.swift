import Foundation

struct Environment {
    fileprivate static func plist(_ name: String) -> NSDictionary? {
        guard let path = Bundle.main
            .path(forResource: name, ofType: "plist") else { return nil }
        return NSDictionary(contentsOfFile: path)
    }
}
