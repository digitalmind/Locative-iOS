import Eureka

fileprivate extension String {
    static let globalHttpSettings = NSLocalizedString("Global HTTP Settings", comment: "Global HTTP Settings")
    static let url = NSLocalizedString("URL", comment: "URL")
    static let urlPlaceholder = NSLocalizedString("http://yourserver.com/event.php", comment: "")
}

class SettingsVc: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        form
        +++ Section(.globalHttpSettings)
            <<< TextRow() { row in
                row.title = .url
                row.placeholder = .urlPlaceholder
        }
    }
}
