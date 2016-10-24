import Eureka
import OnePasswordExtension
import SVProgressHUD

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
    
    fileprivate func usernameRow() -> TextRow? {
        return form.rowBy(tag: .accountUsernameRow) as? TextRow
    }
    
    fileprivate func passwordRow() -> TextRow? {
        return form.rowBy(tag: .accountPasswordRow) as? TextRow
    }
    
    func onePasswordButton(_ frame: CGRect = CGRect(x: 0, y: 0, width: 25, height: 25)) -> UIButton {
        let url = Bundle(for: OnePasswordExtension.self)
            .url(forResource: "OnePasswordExtensionResources", withExtension: "bundle")
        let bundle = Bundle(url: url!)
        let image = UIImage(named: "onepassword-button", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(type: .custom)
        button.frame = frame
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(SettingsVc.loginUsingOnePassword), for: .touchUpInside)
        button.tintColor = .black
        return button
    }
    
    func loginUsingOnePassword(_ sender: Any?) {
        OnePasswordExtension.shared().findLogin(forURLString: "https://my.locative.io", for: self, sender: sender) { [weak self] loginDictionary, error in
            guard let credentials = loginDictionary, credentials.count > 0 else { return }
            self?.usernameRow()?.value = credentials[AppExtensionUsernameKey] as? String
            self?.passwordRow()?.value = credentials[AppExtensionPasswordKey] as? String
            self?.login()
        }
    }
    
    func login() {
        SVProgressHUD.show(withMaskType: UInt(SVProgressHUDMaskTypeClear))
        guard let username = usernameRow()?.value, let password = passwordRow()?.value else {
            return SVProgressHUD.dismiss()
        }
        let credentials = CloudCredentials(username: username, email: nil, password: password)
        appDelegate.cloudManager.loginToAccount(with: credentials) { [weak self] error, sessionId in
            SVProgressHUD.dismiss()
            
            if error == nil {
                self?.appDelegate.settings?.apiToken = sessionId
                self?.appDelegate.settings?.persist()
                self?.form.allRows.forEach { $0.evaluateHidden() }
            }
            
            let alert = UIAlertController(
                title: error == nil ? NSLocalizedString("Success", comment: "Success") : NSLocalizedString("Error", comment: "Error"),
                message: error == nil ? NSLocalizedString("Login successful! Your triggered geofences will now be visible in you Account at http://my.locative.io!", comment: "") : NSLocalizedString("There has been a problem with your login, please try again!", comment: ""),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    func logout() {
        appDelegate.settings?.removeApiToken()
        form.allRows.forEach { $0.evaluateHidden() }
    }
    
    func lostPassword() {
        let alert = UIAlertController(
            title: NSLocalizedString("Note", comment: ""),
            message: NSLocalizedString("This will open up Safari and lead you to the password recovery website. Sure?", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("No", comment: ""),
            style: .cancel,
            handler: nil))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("Yes", comment: ""),
            style: .default) { action in
                UIApplication.shared.openURL(URL(string: "https://my.locative.io/youforgot")!)
        })
        present(alert, animated: true, completion: nil)
    }
    
    func saveSettings() {
        appDelegate.settings?.persist()
    }
}

fileprivate extension SettingsVc {
    static let globalHttpAuthCondition = Condition.function(["globalHttpAuth"]) { form in
        return !((form.rowBy(tag: "globalHttpAuth") as? SwitchRow)?.value ?? false)
    }
    func globalHttpSection() -> Section {
        return Section(.globalHttpSettings)
            <<< TextRow() { [weak self] row in
                row.title = .url
                row.placeholder = .urlPlaceholder
                row.value = self?.appDelegate.settings?.globalUrl?.absoluteString
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
                }.onChange { [weak self] row in
                    guard let url = row.value else {
                        self?.appDelegate.settings?.globalUrl = nil
                        return
                    }
                    self?.appDelegate.settings?.globalUrl = URL(string: url)
                    self?.saveSettings()
            }
            <<< SegmentedRow<String>() { row in
                row.options = [.post, .get]
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    guard let selected = self?.appDelegate.settings?.globalHttpMethod?.intValue else {
                        return
                    }
                    row.value = row.options[selected]
                }.onChange { [weak self] row in
                    self?.appDelegate.settings?.globalHttpMethod =
                        NSNumber(value: row.value == "POST" ? 0 : 1)
                    self?.appDelegate.settings?.persist()
            }
            <<< SwitchRow("globalHttpAuth") { [weak self] row in
                row.title = .httpBasicAuth
                    row.value = self?.appDelegate.settings?.httpBasicAuthEnabled?.boolValue
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
                }.onChange { [weak self] row in
                    self?.appDelegate.settings?.httpBasicAuthEnabled
                        = NSNumber(booleanLiteral: row.value!)
                    self?.appDelegate.settings?.persist()
            }
            <<< TextRow() { row in
                row.title = .httpUsername
                row.placeholder = "Johnny"
                row.hidden = SettingsVc.globalHttpAuthCondition
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
            }
            <<< TextRow() { row in
                row.title = .httpPassword
                row.placeholder = "Appleseed"
                row.hidden = SettingsVc.globalHttpAuthCondition
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.isSecureTextEntry = true
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
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

fileprivate extension String {
    static let accountUsernameRow = "acountUsernameRow"
    static let accountPasswordRow = "accountPasswordRow"
    static let accountSectionTag = "accountSection"
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
        return Section(.account) { section in
                section.tag = .accountSectionTag
            }
            <<< TextRow(.accountUsernameRow) { row in
                row.title = .accountUsername
                row.placeholder = "Johnny"
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
        }
            <<< TextRow(.accountPasswordRow) { row in
                row.title = .accountPassword
                row.placeholder = "Appleseed"
                row.hidden = loginCondition()
                }.cellSetup { [unowned self] cell, row in
                    cell.tintColor = .locativeColor
                    if OnePasswordExtension.shared().isAppExtensionAvailable() {
                        cell.accessoryView = self.onePasswordButton()
                    }
                    cell.textField.isSecureTextEntry = true
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
        }
            <<< ButtonRow() { row in
                row.title = .accountLogin
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.login()
            }
            <<< ButtonRow() { row in
                row.title = .accountSignup
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.performSegue(withIdentifier: "Signup", sender: self)
        }
            <<< ButtonRow() { row in
                row.title = .accountRecover
                row.hidden = loginCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.lostPassword()
        }
            <<< ButtonRow() { row in
                row.title = .accountLogout
                row.hidden = logoutCondition()
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.logout()
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
