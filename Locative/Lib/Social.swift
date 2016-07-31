import UIKit
import PSTAlertController

enum SocialType {
    case Facebook, Twitter
    func readable() -> String {
        switch self {
        case .Facebook:
            return "Facebook"
        case .Twitter:
            return "Twitter"
        }
    }
}

class Social: NSObject {
    static let app = UIApplication.sharedApplication()
    
    private class func openTwitter() -> Bool {
        if app.canOpenURL(NSURL(string: "twitter://")!) {
            return app.openURL(NSURL(string: "twitter://user?screen_name=LocativeHQ")!)
        }
        return app.openURL(NSURL(string: "http://twitter.com/LocativeHQ")!)
    }
    
    private class func openFacebook() -> Bool {
        if app.canOpenURL(NSURL(string: "fb://")!) {
            return app.openURL(NSURL(string: "fb://profile/329978570476013")!)
        }
        return app.openURL((NSURL(string: "http://facebook.com/LocativeHQ")!))
    }
    
    class func open(type: SocialType) {
        switch type {
        case .Facebook:
            openFacebook()
        case .Twitter:
            openTwitter()
        }
    }
}

extension UIViewController {
    func askToOpenSocial(type: SocialType) {
        let controller = PSTAlertController(
            title: NSLocalizedString("Note", comment: "Social alert title"),
            message: String(format: NSLocalizedString("This will open up %@. Ready?", comment: "Open social link alert test"), type.readable()),
            preferredStyle: .Alert
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("No", comment: "Social alert no button"), style: .Cancel, handler: { action in
                
            })
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("Yes", comment: "Social alert yes button"), style: .Default, handler: { action in
                
            })
        )
        controller.showWithSender(self, controller: self, animated: true) {}
    }
}