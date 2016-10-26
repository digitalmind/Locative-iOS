import Foundation

private extension String {
    static let shortVersionString = "CFBundleShortVersionString"
    static let shortVersion = "CFBundleVersion"
}

extension Bundle {
    func versionString() -> String {
        guard let infoDict = Bundle.main.infoDictionary else {
            return "Unknown Version"
        }
        return "Version".appendingFormat(
            " %@ (%@)",
            infoDict[.shortVersionString] as! String,
            infoDict[.shortVersion] as! String
        )
    }
}
