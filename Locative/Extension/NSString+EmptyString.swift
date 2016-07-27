import Foundation

extension NSString {
    @objc(lct_isNotEmpty) func isNotEmpty () -> Bool {
        if self.length > 0 {
            return true
        }
        return false
    }
}