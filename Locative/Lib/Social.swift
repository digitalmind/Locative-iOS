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
    let app = UIApplication.sharedApplication()
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }
    
    func openTwitter() {
        askToOpenSocial(.Twitter) { [weak self] allowed in
            guard let this = self else { return }
            if allowed {
                if this.app.canOpenURL(NSURL(string: "twitter://")!) {
                    this.app.openURL(NSURL(string: "twitter://user?screen_name=LocativeHQ")!)
                    return
                }
                this.app.openURL(NSURL(string: "http://twitter.com/LocativeHQ")!)
            }
        }
    }
    
    func openFacebook() {
        askToOpenSocial(.Facebook) { [weak self] allowed in
            guard let this = self else { return }
            if allowed {
                if this.app.canOpenURL(NSURL(string: "fb://")!) {
                    this.app.openURL(NSURL(string: "fb://profile/329978570476013")!)
                    return
                }
                this.app.openURL((NSURL(string: "http://facebook.com/LocativeHQ")!))
            }
        }
    }
}

private extension Social {
    func askToOpenSocial(type: SocialType, completion:(allowed: Bool)->()) {
        let controller = PSTAlertController(
            title: NSLocalizedString("Note", comment: "Social alert title"),
            message: String(format: NSLocalizedString("This will open up %@. Ready?", comment: "Open social link alert test"), type.readable()),
            preferredStyle: .Alert
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("No", comment: "Social alert no button"), style: .Cancel, handler: { action in
                completion(allowed: false)
            })
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("Yes", comment: "Social alert yes button"), style: .Default, handler: { action in
                completion(allowed: true)
            })
        )
        controller.showWithSender(self, controller: viewController, animated: true) {}
    }
}