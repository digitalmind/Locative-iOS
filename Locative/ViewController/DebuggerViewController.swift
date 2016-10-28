import Eureka
import CoreLocation

fileprivate extension String {
    static let monitoredRegions = NSLocalizedString("Monitored Regions", comment: "")
    static let rangedRegions = NSLocalizedString("Ranged Regions", comment: "")
}

class DebuggerViewController: FormViewController {
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Debugger", comment: "Debugger")
        
        form
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
