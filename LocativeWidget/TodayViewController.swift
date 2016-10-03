import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, URLSessionDelegate {

    @IBOutlet weak var label: UILabel!
    fileprivate let defaults = UserDefaults(suiteName: "group.marcuskida.Geofancy")

    var sessionId: String? {
        get {
            return defaults?.string(forKey: "sessionId")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func widgetPerformUpdate(completionHandler: @escaping (NCUpdateResult) -> Void) {
        guard let sId = sessionId else {
            return completionHandler(.noData)
        }
        
        let session = URLSession.shared
        let task = session.dataTask(
            with: URL(string: "https://my.locative.io/api/today\(["sessionId": sId].queryString())")!, completionHandler: { [weak self] data, response, error in
            if let _ = error {
                self?.updateLabel(nil)
                return completionHandler(.newData)
            }
            guard let res = response as? HTTPURLResponse else {
                self?.showGenericError()
                return completionHandler(.newData)
            }
            if res.statusCode == 404 {
                self?.showNoVisits()
                return completionHandler(.newData)
            }
            guard let d = data, let json = try? JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? [String: AnyObject] else {
                self?.showGenericError()
                return completionHandler(.newData)
            }
            guard let j = json, let fencelog = j["fencelog"] as? [String: AnyObject] else {
                self?.showGenericError()
                return completionHandler(.newData)
            }
            guard let locationId = fencelog["locationId"] as? String else {
                self?.showGenericError()
                return completionHandler(.newData)
            }
            self?.updateLabel(
                NSLocalizedString("You last visited", comment: "You last visited") + " \(locationId)."
            )
        }
        ) 
        task.resume()
    }
    
    fileprivate func updateLabel(_ string: String?) {
        guard let s = string else { return label.text = nil }
        main { [weak self] in
            self?.label.text = s.characters.count > 0 ? s : NSLocalizedString(
                "Please login using the Locative App by tapping here.",
                comment: "Login text for widget"
            )
        }
    }
    
    fileprivate func showNoVisits() {
        main { [weak self] in
            self?.label.text = NSLocalizedString(
                "You have not visited any locations.",
                comment: "You have not visited any locations."
            )
        }
    }
    
    fileprivate func showGenericError() {
        main { [weak self] in
            self?.label.text = NSLocalizedString(
                "Error updating last visited location.",
                comment: "Error updating last visited location."
            )
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = sessionId else {
            extensionContext?.open(
                URL(string: "locative://open?ref=todaywidget&openSettings=true")!,
                completionHandler: nil
            )
            return
        }
        extensionContext?.open(
            URL(string: "locative://open?ref=todaywidget")!,
            completionHandler: nil)
    }
}

private extension TodayViewController {
    func main(_ closure:@escaping ()->Void) {
        DispatchQueue.main.async(execute: closure)
    }
}

private extension Dictionary {
    func queryString() -> String {
        var urlVars:[String] = []
        for (k, value) in self {
            if let encodedValue = (value as! String).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                urlVars.append((k as! String) + "=" + encodedValue)
            }
        }
        
        return urlVars.isEmpty ? "" : "?" + urlVars.joined(separator: "&")
    }
}
