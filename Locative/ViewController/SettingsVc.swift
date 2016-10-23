import Eureka

fileprivate extension String {
    static let globalHttpSettings = NSLocalizedString("Global HTTP Settings", comment: "Global HTTP Settings")
    static let url = NSLocalizedString("URL", comment: "URL")
    static let urlPlaceholder = NSLocalizedString("http://yourserver.com/event.php", comment: "")
    static let post = NSLocalizedString("POST", comment: "POST")
    static let get = NSLocalizedString("GET", comment: "GET")
    static let httpBasicAuth = NSLocalizedString("HTTP Basic Authentication", comment: "HTTP Basic Authentication")
    static let httpUsername = NSLocalizedString("Username", comment: "Username")
    static let httpPassword = NSLocalizedString("Password", comment: "Password")
    static let testRequest = NSLocalizedString("Send Test-Request", comment: "Send Test-Request")
}

extension UIColor {
    static let locativeColor = UIColor(red: 24.0/255.0, green: 169.0/255.0, blue: 228.0/255.0, alpha: 1.0)
}

class SettingsVc: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        form
        +++ Section(.globalHttpSettings)
            <<< TextRow() { row in
                row.title = .url
                row.placeholder = .urlPlaceholder
            }.cellSetup { cell, row in
                cell.tintColor = .locativeColor
        }
            <<< SegmentedRow<String>() { row in
                row.options = [.post, .get]
            }.cellSetup { cell, row in
                cell.tintColor = .locativeColor
                cell.segmentedControl.selectedSegmentIndex = 0
        }
            <<< SwitchRow() { row in
                row.title = .httpBasicAuth
            }.cellSetup { cell, row in
                cell.tintColor = .locativeColor
                cell.switchControl?.tintColor = .locativeColor
        }
            <<< TextRow() { row in
                row.title = .httpUsername
                row.placeholder = "Johnny"
            }.cellSetup { cell, row in
                cell.tintColor = .locativeColor
        }            <<< TextRow() { row in
                row.title = .httpPassword
                row.placeholder = "Appleseed"
            }.cellSetup { cell, row in
                cell.tintColor = .locativeColor
                cell.textField.isSecureTextEntry = true
        }
            <<< ButtonRow() { row in
                row.title = .testRequest
            }.cellSetup { cell, row in
                cell.tintColor = .locativeColor
        }
    }
}
