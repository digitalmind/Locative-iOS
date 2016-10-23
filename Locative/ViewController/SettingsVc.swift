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
    
    static let notifications = NSLocalizedString("Notifications", comment: "Notifications")
    static let notificationOnSuccess = NSLocalizedString("Notification on Success", comment: "Notification on Success")
    static let notificationOnFailure = NSLocalizedString("Notification on Failure", comment: "Notification on Failure")
    static let soundOnNotification = NSLocalizedString("Sound on Notification", comment: "Sound on Notification")
    
    static let account = NSLocalizedString("My Locative Account", comment: "My Locative Account")
    static let accountUsername = NSLocalizedString("Username", comment: "Username")
    static let accountPassword = NSLocalizedString("Password", comment: "Password")
    static let accountLogin = NSLocalizedString("Login", comment: "Login")
    static let accountSignup = NSLocalizedString("Signup new Account", comment: "Signup new Account")
    static let accountRecover = NSLocalizedString("Recover lost password", comment: "Recover lost password")
    static let accountLogout = NSLocalizedString("Logout", comment: "Logout")
    
    static let backup = NSLocalizedString("Backup", comment: "Backup")
    static let exportGpx = NSLocalizedString("Export Geofences as GPX", comment: "Export Geofences as GPX")
}

fileprivate extension UIColor {
    static let locativeColor = UIColor(red: 24.0/255.0, green: 169.0/255.0, blue: 228.0/255.0, alpha: 1.0)
}

class SettingsVc: FormViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        form
        +++ globalHttpSection()
        +++ notificationsSection()
        +++ accountSection()
        +++ backupSection()
    }
    
    @IBAction func saveSettings(sender: UIBarButtonItem) {
        
    }
}

fileprivate extension SettingsVc {
    static let globalHttpAuthCondition = Condition.function(["globalHttpAuth"]) { form in
        return !((form.rowBy(tag: "globalHttpAuth") as? SwitchRow)?.value ?? false)
    }
    func globalHttpSection() -> Section {
        return Section(.globalHttpSettings)
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
            <<< SwitchRow("globalHttpAuth") { row in
                row.title = .httpBasicAuth
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
            }
            <<< TextRow() { row in
                row.title = .httpUsername
                row.placeholder = "Johnny"
                row.hidden = SettingsVc.globalHttpAuthCondition
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
            }            <<< TextRow() { row in
                row.title = .httpPassword
                row.placeholder = "Appleseed"
                row.hidden = SettingsVc.globalHttpAuthCondition
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

fileprivate extension SettingsVc {
    func notificationsSection() -> Section {
        return Section(.notifications)
            <<< SwitchRow() { row in
                row.title = .notificationOnSuccess
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
        }
            <<< SwitchRow() { row in
                row.title = .notificationOnFailure
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
        }
            <<< SwitchRow() { row in
                row.title = .soundOnNotification
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
        }
    }
}

fileprivate extension SettingsVc {
    func isLoggedIn() -> Bool {
        guard let token = appDelegate.settings?.apiToken else {
            return false
        }
        return token.characters.count > 0
    }
    func loginCondition() -> Condition {
        return Condition.function([]) { [unowned self] form in
            return self.isLoggedIn()
        }
    }
    func logoutCondition() -> Condition {
        return Condition.function([]) { [unowned self] form in
            return !self.isLoggedIn()
        }
    }
    func accountSection() -> Section {
        return Section(.account)
            <<< TextRow() { row in
                row.title = .accountUsername
                row.placeholder = "Johnny"
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
            <<< TextRow() { row in
                row.title = .accountPassword
                row.placeholder = "Appleseed"
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
            <<< ButtonRow() { row in
                row.title = .accountLogin
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
            <<< ButtonRow() { row in
                row.title = .accountSignup
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
            <<< ButtonRow() { row in
                row.title = .accountRecover
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
            <<< ButtonRow() { row in
                row.title = .accountLogout
                row.hidden = logoutCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
    }
}

fileprivate extension SettingsVc {
    func backupSection() -> Section {
        return Section(.backup)
            <<< ButtonRow() { row in
                row.title = .exportGpx
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
        }
    }
}
