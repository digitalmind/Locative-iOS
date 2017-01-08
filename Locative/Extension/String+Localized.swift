import Foundation

extension String {
    func localized(comment: String? = nil) -> String {
        return NSLocalizedString(self, comment: comment == nil ? self : comment!)
    }
}
