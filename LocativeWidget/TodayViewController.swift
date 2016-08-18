import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, NSURLSessionDelegate {

    @IBOutlet weak var label: UILabel!
    private let defaults = NSUserDefaults(suiteName: "group.marcuskida.Geofancy")

    var sessionId: String? {
        get {
            return defaults?.stringForKey("sessionId")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func widgetPerformUpdateWithCompletionHandler(completionHandler: (NCUpdateResult) -> Void) {
        guard let sId = sessionId else {
            return completionHandler(.NoData)
        }
        
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(
            NSURL(string: "https://my.locative.io/api/today\(["sessionId": sId].queryString())")!
        ) { [weak self] data, response, error in
            if let _ = error {
                self?.updateLabel(nil)
                return completionHandler(.NewData)
            }
            guard let res = response as? NSHTTPURLResponse else {
                self?.showGenericError()
                return completionHandler(.NewData)
            }
            if res.statusCode == 404 {
                self?.showNoVisits()
                return completionHandler(.NewData)
            }
            guard let d = data, json = try? NSJSONSerialization.JSONObjectWithData(d, options: NSJSONReadingOptions(rawValue: 0)) as? [String: AnyObject] else {
                self?.showGenericError()
                return completionHandler(.NewData)
            }
            guard let j = json, fencelog = j["fencelog"] as? [String: AnyObject] else {
                self?.showGenericError()
                return completionHandler(.NewData)
            }
            guard let locationId = fencelog["locationId"] as? String else {
                self?.showGenericError()
                return completionHandler(.NewData)
            }
            self?.updateLabel(
                NSLocalizedString("You last visited", comment: "You last visited").stringByAppendingString(" \(locationId).")
            )
        }
        task.resume()
    }
    
    private func updateLabel(string: String?) {
        guard let s = string else { return label.text = nil }
        main { [weak self] in
            self?.label.text = s.characters.count > 0 ? s : NSLocalizedString(
                "Please login using the Locative App by tapping here.",
                comment: "Login text for widget"
            )
        }
    }
    
    private func showNoVisits() {
        main { [weak self] in
            self?.label.text = NSLocalizedString(
                "You have not visited any locations.",
                comment: "You have not visited any locations."
            )
        }
    }
    
    private func showGenericError() {
        main { [weak self] in
            self?.label.text = NSLocalizedString(
                "Error updating last visited location.",
                comment: "Error updating last visited location."
            )
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let _ = sessionId else {
            extensionContext?.openURL(
                NSURL(string: "locative://open?ref=todaywidget&openSettings=true")!,
                completionHandler: nil
            )
            return
        }
        extensionContext?.openURL(
            NSURL(string: "locative://open?ref=todaywidget")!,
            completionHandler: nil)
    }
}

private extension TodayViewController {
    func main(closure:()->Void) {
        dispatch_async(dispatch_get_main_queue(), closure)
    }
}

private extension Dictionary {
    func queryString() -> String {
        var urlVars:[String] = []
        for (k, value) in self {
            if let encodedValue = (value as! String).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                urlVars.append((k as! String) + "=" + encodedValue)
            }
        }
        
        return urlVars.isEmpty ? "" : "?" + urlVars.joinWithSeparator("&")
    }
}
