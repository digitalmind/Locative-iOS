import Eureka
import VTAcknowledgementsViewController
import SafariServices

class AboutViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let social = Social(viewController: self)
    
        form
              
        +++ Section(NSLocalizedString("Get in touch", comment: "Get in touch"))
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
                    UIApplication.shared.openURL(NSURL(string: "https://my.locative.io/support")! as URL)
                }
        }
            
        +++ Section(NSLocalizedString("Acknowledgements", comment: "Acknowledgements header"))
            <<< ButtonRow {
                $0.title = NSLocalizedString("Licenses", comment: "Licenses button")
                $0.onCellSelection { [weak self] cell, row in
                    if let controller = VTAcknowledgementsViewController(fileNamed: "Acknowledgements") {
                        controller.title = NSLocalizedString("Licenses", comment: "Licenses header")
                        if let file = Bundle.main.path(forResource: "Licenses", ofType: "plist"),
                            let licenses = NSDictionary(contentsOfFile: file)?["licenses"] as? [[String: String]] {
                            controller.acknowledgements?.append(contentsOf: licenses.map {
                                return VTAcknowledgement(title: $0["name"]!, text: $0["text"]!, license: "See License Text")
                            })
                        }
                        controller.acknowledgements?.sort {
                            $0.0.title.compare($0.1.title) == .orderedAscending
                        }
                        controller.footerText = "Made with ❤️ and Open Source Software"
                        self?.navigationController?.pushViewController(controller, animated: true)
                    }
                }
            }
            <<< ButtonRow() {
                $0.title = NSLocalizedString("Legal", comment: "Legal button")
                $0.onCellSelection { cell, row in
                    UIApplication.shared.openURL(NSURL(string: "https://my.locative.io/legal")! as URL)
                }
            }

        +++ Section(footer: Bundle.main.versionString())
    }
}
