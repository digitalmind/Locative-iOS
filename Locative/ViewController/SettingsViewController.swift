import Eureka
import OnePasswordExtension
import SVProgressHUD
import iOS_GPX_Framework

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
    
    static let debugging = NSLocalizedString("Debugging", comment: "Debugging")
    static let openDebugger = NSLocalizedString("Open Debugger", comment: "Open Debugger")
}

fileprivate extension UIColor {
    static let locativeColor = UIColor(red: 24.0/255.0, green: 169.0/255.0, blue: 228.0/255.0, alpha: 1.0)
}

class SettingsViewController: FormViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var debouncer: Debouncer?
    var locationManager: LocationManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        form
            +++ accountSection()
            +++ notificationsSection()
            +++ globalHttpSection()
            +++ backupSection()
            +++ debugSection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        form.allRows.forEach { $0.evaluateHidden() }
        form.sectionBy(tag: .debugging)?.evaluateHidden()
    }

    fileprivate func usernameRow() -> TextRow? {
        return form.rowBy(tag: .accountUsernameRow) as? TextRow
    }
    
    fileprivate func passwordRow() -> TextRow? {
        return form.rowBy(tag: .accountPasswordRow) as? TextRow
    }
    
    fileprivate func persistSettings() {
        if let debouncer = debouncer, debouncer.isValid {
            debouncer.cancel()
        }
        debouncer = Debouncer({ [weak self] in
            self?.appDelegate.settings.persist()
        })
    }
    
    func onePasswordButton(_ frame: CGRect = CGRect(x: 0, y: 0, width: 25, height: 25)) -> UIButton {
        let url = Bundle(for: OnePasswordExtension.self)
            .url(forResource: "OnePasswordExtensionResources", withExtension: "bundle")
        let bundle = Bundle(url: url!)
        let image = UIImage(named: "onepassword-button", in: bundle, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let button = UIButton(type: .custom)
        button.frame = frame
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(SettingsViewController.loginUsingOnePassword), for: .touchUpInside)
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
                self?.appDelegate.settings.apiToken = sessionId
                self?.persistSettings()
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
        appDelegate.settings.removeApiToken()
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
    
    func testRequest() {
        locationManager = LocationManager { [weak self] location in
            let coordinate = location?.coordinate
            let timestamp = Date()
            let parameters = [
                "trigger": "test",
                "device": UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                "device_type": UIDevice.current.model,
                "device_model": UIDevice.locative_deviceModel(),
                "latitude": coordinate != nil ? Double(coordinate!.latitude) : 123.0,
                "longitude": coordinate != nil ? Double(coordinate!.longitude) : 123.0,
                "timestamp": Int(timestamp.timeIntervalSince1970)
                ] as NSDictionary
            
            let request = HttpRequest()
            request.url = self?.appDelegate.settings.globalUrl?.absoluteString
            request.method = self?.appDelegate.settings.globalHttpMethod == 0 ? "POST" : "GET"
            request.parameters = parameters
            request.eventType = NSNumber(integerLiteral: 0)
            request.timestamp = timestamp as NSDate
            request.uuid = NSUUID().uuidString
            
            if let auth = self?.appDelegate.settings.httpBasicAuthEnabled, auth == true {
                request.httpAuth = NSNumber(booleanLiteral: true)
                request.httpAuthUsername = self?.appDelegate.settings.httpBasicAuthUsername
                request.httpAuthPassword = self?.appDelegate.settings.httpBasicAuthPassword
            }
            
            self?.appDelegate.requestManager.dispatch(request)
            
            let alert = UIAlertController(
                title: NSLocalizedString("Note", comment: "Note"),
                message: NSLocalizedString("A Test-Request has been sent. The result will be displayed as soon as it's succeeded / failed.", comment: "A Test-Request has been sent. The result will be displayed as soon as it's succeeded / failed."),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("OK", comment: "OK"),
                style: .default,
                handler: nil)
            )
            self?.present(alert, animated: true, completion: nil)
        }
    }
    
    func exportGpx(inView: UIView) {
        
        func gpxCreator() -> String {
            return "Locative iOS - \(Bundle.main.versionString())"
        }
        
        func temporaryPath() -> URL {
            return NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Geofences.gpx")!
        }
        
        func share(gpx: String, view: UIView) {
            if let _ = try? gpx.data(using: String.Encoding.utf8)?.write(to: temporaryPath()) {
                let controller = UIDocumentInteractionController(url: temporaryPath())
                controller.presentOptionsMenu(from: view.frame, in: view, animated: true)
                return
            }
            
            let alert = UIAlertController(
                title: NSLocalizedString("Error", comment: "Error"),
                message: NSLocalizedString("Something went wrong when exporting your Geofences.", comment: "Something went wrong when exporting your Geofences."),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
        func createGpx(inView: UIView) {
            SVProgressHUD.show(withMaskType: UInt(SVProgressHUDMaskTypeClear))
            let root = GPXRoot(creator: gpxCreator())!
            
            DispatchQueue(label: "io.locative.iOS.gpx").async {
                let geofences = Geofence.all() as! [Geofence]
                let waypoints = geofences
                    .filter { $0.latitude != nil }
                    .filter { $0.longitude != nil }
                    .map({ (geofence) -> GPXWaypoint in
                    let waypoint = GPXWaypoint(latitude: CGFloat(geofence.latitude!.floatValue), longitude: CGFloat(geofence.longitude!.floatValue))!
                    waypoint.name = geofence.customId ?? geofence.uuid
                    waypoint.comment = geofence.name
                    return waypoint
                }).filter { $0 != nil }
                
                root.addWaypoints(waypoints)
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                    share(gpx: root.gpx(), view: inView)
                }
            }
        }
        
        let alert = UIAlertController(
            title: NSLocalizedString("Note", comment: "Note"),
            message: NSLocalizedString("Your Geofences (no iBeacons) will be exported as an ordinary GPX file, only location and UUID/Name as well as Description will be exported. Custom settings like radius and URLs will fall back to default.", comment: "Your Geofences (no iBeacons) will be exported as an ordinary GPX file, only location and UUID/Name as well as Description will be exported. Custom settings like radius and URLs will fall back to default."),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default) { _ in
            createGpx(inView: inView)
        })
        
        self.present(alert, animated: true, completion: nil)
    }
}

fileprivate extension SettingsViewController {
    static let globalHttpAuthCondition = Condition.function(["globalHttpAuth"]) { form in
        return !((form.rowBy(tag: "globalHttpAuth") as? SwitchRow)?.value ?? false)
    }
    func globalHttpSection() -> Section {
        return Section(.globalHttpSettings)
            <<< TextRow() { [weak self] row in
                row.title = .url
                row.placeholder = .urlPlaceholder
                row.value = self?.appDelegate.settings.globalUrl?.absoluteString
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
                }.onChange { [weak self] row in
                    guard let url = row.value else {
                        self?.appDelegate.settings.globalUrl = nil
                        return
                    }
                    self?.appDelegate.settings.globalUrl = URL(string: url)
                    self?.persistSettings()
            }
            <<< SegmentedRow<String>() { row in
                row.options = [.post, .get]
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    guard let selected = self?.appDelegate.settings.globalHttpMethod?.intValue else {
                        return
                    }
                    row.value = row.options[selected]
                }.onChange { [weak self] row in
                    self?.appDelegate.settings.globalHttpMethod =
                        NSNumber(value: row.value == "POST" ? 0 : 1)
                    self?.persistSettings()
            }
            <<< SwitchRow("globalHttpAuth") { [weak self] row in
                row.title = .httpBasicAuth
                    row.value = self?.appDelegate.settings.httpBasicAuthEnabled?.boolValue
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
                }.onChange { [weak self] row in
                    self?.appDelegate.settings.httpBasicAuthEnabled
                        = NSNumber(booleanLiteral: row.value!)
                    self?.persistSettings()
            }
            <<< TextRow() { row in
                row.title = .httpUsername
                row.placeholder = "Johnny"
                row.hidden = SettingsViewController.globalHttpAuthCondition
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
                    row.value = self?.appDelegate.settings.httpBasicAuthUsername
                }.onChange { [weak self] row in
                    self?.appDelegate.settings.httpBasicAuthUsername = row.value
                    self?.persistSettings()
            }
            <<< TextRow() { row in
                row.title = .httpPassword
                row.placeholder = "Appleseed"
                row.hidden = SettingsViewController.globalHttpAuthCondition
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    cell.textField.isSecureTextEntry = true
                    cell.textField.autocorrectionType = .no
                    cell.textField.autocapitalizationType = .none
                    row.value = self?.appDelegate.settings.httpBasicAuthPassword
                }.onChange { [weak self] row in
                    self?.appDelegate.settings.httpBasicAuthPassword = row.value
                    self?.persistSettings()
            }
            <<< ButtonRow() { row in
                row.title = .testRequest
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.testRequest()
        }
    }
}

fileprivate extension SettingsViewController {
    func notificationsSection() -> Section {
        return Section(.notifications)
            <<< SwitchRow() { row in
                row.title = .notificationOnSuccess
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
                    row.value = self?.appDelegate.settings.notifyOnSuccess?.boolValue
                }.onChange { [weak self] row in
                    let value = row.value ?? false
                    self?.appDelegate.settings.notifyOnSuccess = NSNumber(booleanLiteral: value)
                    self?.persistSettings()
            }
            <<< SwitchRow() { row in
                row.title = .notificationOnFailure
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
                    row.value = self?.appDelegate.settings.notifyOnFailure?.boolValue
                }.onChange { [weak self] row in
                    let value = row.value ?? false
                    self?.appDelegate.settings.notifyOnFailure = NSNumber(booleanLiteral: value)
                    self?.persistSettings()
            }
            <<< SwitchRow() { row in
                row.title = .soundOnNotification
                }.cellSetup { [weak self] cell, row in
                    cell.tintColor = .locativeColor
                    cell.switchControl?.onTintColor = .locativeColor
                    row.value = self?.appDelegate.settings.soundOnNotification?.boolValue
                }.onChange { [weak self] row in
                    let value = row.value ?? false
                    self?.appDelegate.settings.soundOnNotification = NSNumber(booleanLiteral: value)
                    self?.persistSettings()
        }
    }
}

fileprivate extension String {
    static let accountUsernameRow = "acountUsernameRow"
    static let accountPasswordRow = "accountPasswordRow"
    static let accountSectionTag = "accountSection"
}

fileprivate extension SettingsViewController {
    func isLoggedIn() -> Bool {
        guard let token = appDelegate.settings.apiToken else {
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

fileprivate extension SettingsViewController {
    func backupSection() -> Section {
        return Section(.backup)
            <<< ButtonRow() { row in
                row.title = .exportGpx
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.exportGpx(inView: cell)
        }
    }
}

fileprivate extension SettingsViewController {
    func debugSection() -> Section {
        return Section(.debugging) { section in
            section.tag = .debugging
            section.hidden = Condition.function([]) { [weak self] form in
                guard let e = self?.appDelegate.settings.debugEnabled else {
                    return true
                }
                return !e.boolValue
                }
            }
            <<< ButtonRow() { row in
                row.title = .openDebugger
                }.cellSetup { cell, row in
                    cell.tintColor = .locativeColor
                }.onCellSelection { [weak self] cell, row in
                    self?.navigationController?.pushViewController(DebuggerViewController(), animated: true)
        }
    }
}
