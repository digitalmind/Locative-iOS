import UIKit
import PSTAlertController

enum SocialType {
    case facebook, twitter
    func readable() -> String {
        switch self {
        case .facebook:
            return "Facebook"
        case .twitter:
            return "Twitter"
        }
    }
}

class Social: NSObject {
    let app = UIApplication.shared
    let viewController: UIViewController
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }
    
    func openTwitter() {
        askToOpenSocial(.twitter) { [weak self] allowed in
            guard let this = self else { return }
            if allowed {
                if this.app.canOpenURL(URL(string: "twitter://")!) {
                    this.app.openURL(URL(string: "twitter://user?screen_name=LocativeHQ")!)
                    return
                }
                this.app.openURL(URL(string: "http://twitter.com/LocativeHQ")!)
            }
        }
    }
    
    func openFacebook() {
        askToOpenSocial(.facebook) { [weak self] allowed in
            guard let this = self else { return }
            if allowed {
                if this.app.canOpenURL(URL(string: "fb://")!) {
                    this.app.openURL(URL(string: "fb://profile/329978570476013")!)
                    return
                }
                this.app.openURL((URL(string: "http://facebook.com/LocativeHQ")!))
            }
        }
    }
}

private extension Social {
    func askToOpenSocial(_ type: SocialType, completion:@escaping (_ allowed: Bool)->()) {
        let controller = PSTAlertController(
            title: NSLocalizedString("Note", comment: "Social alert title"),
            message: String(format: NSLocalizedString("This will open up %@. Ready?", comment: "Open social link alert test"), type.readable()),
            preferredStyle: .alert
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("No", comment: "Social alert no button"), style: .cancel, handler: { action in
                completion(false)
            })
        )
        controller.addAction(
            PSTAlertAction(title: NSLocalizedString("Yes", comment: "Social alert yes button"), style: .default, handler: { action in
                completion(true)
            })
        )
        controller.showWithSender(self, controller: viewController, animated: true) {}
    }
}
