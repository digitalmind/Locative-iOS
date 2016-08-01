import Eureka
import VTAcknowledgementsViewController
import SafariServices

private extension String {
    static let shortVersionString = "CFBundleShortVersionString"
    static let shortVersion = "CFBundleVersion"
}

class AboutViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let social = Social(viewController: self)
    
        form +++ Section(NSLocalizedString("Get in touch", comment: "Get in touch"))
            <<< ButtonRow {
                $0.title = "Facebook"
                $0.onCellSelection { cell, row in
                    social.openFacebook()
                }
        }
            <<< ButtonRow {
                $0.title = "Twitter"
                $0.onCellSelection { cell, row in
                    social.openTwitter()
                }
        }
        
        +++ Section(NSLocalizedString("Support", comment: "Support header"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("Support request", comment: "Support request button")
                $0.onCellSelection { cell, row in
                    UIApplication.sharedApplication().openURL(NSURL(string: "https://my.locative.io/support")!)
                }
        }
            
        +++ Section(NSLocalizedString("Licenses", comment: "Licenses header"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("Open Source", comment: "Open Source licenses button")
                $0.onCellSelection { [weak self] cell, row in
                    if let controller = VTAcknowledgementsViewController(fileNamed: "Acknowledgements") {
                        controller.title = NSLocalizedString("Licenses", comment: "Licenses header")
                        controller.footerText = "Made with ❤️ and Open Source Software"
                        self?.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
            
        +++ Section(NSLocalizedString("Artwork", comment: "Artwork license header"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("Creative Commons License", comment: "Creative Commons License license button")
                $0.onCellSelection { cell, row in
                    
                }
            }
            
            <<< ButtonRow {
                $0.title = "UITabBar Icons by Icons Design"
                $0.onCellSelection { cell, row in
                    UIApplication.sharedApplication().openURL(NSURL(string: "https://www.iconfinder.com/dreamer0810")!)
                }
            }
        
        +++ Section(footer: versionString())
    }
}

private extension AboutViewController {
    func versionString() -> String {
        guard let infoDict = NSBundle.mainBundle().infoDictionary else {
            return "Unknown Version"
        }
        return "Version".stringByAppendingFormat(
            " %@ (%@)",
            infoDict[.shortVersionString] as! String,
            infoDict[.shortVersion] as! String
        )
    }
}