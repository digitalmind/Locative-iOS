import Eureka
import CoreLocation

fileprivate extension String {
    static let overrides = NSLocalizedString("Overrides", comment: "")
    static let monitoredRegions = NSLocalizedString("Monitored Regions", comment: "")
    static let rangedRegions = NSLocalizedString("Ranged Regions", comment: "")
}

class DebuggerViewController: FormViewController {
    
    let locationManager = CLLocationManager()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Debugger", comment: "Debugger")
        
        form
            +++ Section(.overrides) { section in
                section.tag = .overrides
            }
            <<< SwitchRow() { [unowned self] row in
                row.title = "Override trigger threshold"
                row.value = self.appDelegate.settings?.overrideTriggerThreshold.boolValue
            }.onChange { [unowned self] row in
                self.appDelegate.settings?.overrideTriggerThreshold = NSNumber(booleanLiteral: row.value ?? false)
                self.appDelegate.settings?.persist()
            }
            +++ Section(.monitoredRegions) { section in
                section.tag = .monitoredRegions
        }
            +++ Section(.rangedRegions) { section in
                section.tag = .rangedRegions
                section.hidden = Condition.function([]) { form in
                    return true
                }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        form.sectionBy(tag: .monitoredRegions)?.removeAll()
        form.sectionBy(tag: .rangedRegions)?.removeAll()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.monitoredRegions
            .insert(intoSection: form.sectionBy(tag: .monitoredRegions)!)
        
        locationManager.rangedRegions
            .insert(intoSection: form.sectionBy(tag: .rangedRegions)!)
    }
}

fileprivate extension Set where Element: CLRegion {
    func insert(intoSection: Section) {
        self.map { region in
            return TextAreaRow() { row in
                row.value = region.debugDescription
                row.disabled = true
                row.textAreaHeight = .dynamic(initialTextViewHeight: 110)
            }
        }.forEach { row in
            intoSection <<< row
        }
    }
}
