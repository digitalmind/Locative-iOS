import UIKit
import SVProgressHUD

private extension String {
    static let cellName = "WebhookCell"
}

private extension Int {
    func sentString() -> String {
        return self == 0 ? "Not yet sent." : "Failed \(self) times."
    }
}

final class WebhookViewController: UITableViewController {
    
    let dateFormatter = NSDateFormatter()
    var webhooks = [HttpRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("HTTP Webhooks", comment: "HTTP WebhooksViewController title")
        tableView.registerNib(UINib.init(nibName: .cellName, bundle: nil), forCellReuseIdentifier: .cellName)
        
        // Setup date formatter
        dateFormatter.timeStyle = .MediumStyle
        dateFormatter.dateStyle = .MediumStyle
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        reloadData()
    }
}

private extension WebhookViewController {
    func reloadData() {
        webhooks = validWebhooks()
        tableView.reloadSections(
            NSIndexSet(index: 0),
            withRowAnimation: .Automatic
        )
    }
    
    func validWebhooks() -> [HttpRequest] {
        return (HttpRequest.all() as! [HttpRequest]).filter { req in
            req.parameters != nil
        }
    }
}

// MARK: - UITableViewDatasource
extension WebhookViewController {
    override func tableView(
        tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return webhooks.count
    }
}

// MARK: - UITableViewDelegate
extension WebhookViewController {
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(.cellName, forIndexPath: indexPath)
        let request = webhooks[indexPath.row]
        let parameters = request.parameters!
        
        if let id = parameters["id"] as? String {
            cell.textLabel?.text = id
        } else {
            cell.textLabel?.text = "No Location-ID"
        }
        
        if let failCount = request.failCount?.integerValue {
            cell.detailTextLabel?.text =
                "\(dateFormatter.stringFromDate(request.timestamp!)), \(failCount.sentString())"
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        SVProgressHUD.showWithStatus("Sending webhook…")
        HttpRequestManager.sharedManager.dispatch(webhooks[indexPath.row]) { [weak self] success in
            if success {
                return SVProgressHUD.showSuccessWithStatus("Webhook sent successfully.")
            }
            SVProgressHUD.dismiss()
            self?.reloadData()
        }
    }
}