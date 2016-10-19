import UIKit

class NotificationsEmptyView: UIView {
    
    var buttonAction: ((_ button: UIButton) -> Void)?
    
    @IBOutlet weak fileprivate var label: UILabel!
    @IBOutlet weak fileprivate var button: UIButton!
    
    @IBAction fileprivate func buttonPressed(sender: UIButton) {
        if let action = buttonAction {
            action(sender)
        }
    }
}

protocol UIViewLoading {}
extension UIView : UIViewLoading {}

extension UIViewLoading where Self : UIView {
    
    static func loadFromNib() -> Self {
        let nibName = "\(self)".characters.split{$0 == "."}.map(String.init).last!
        let nib = UINib(nibName: nibName, bundle: nil)
        return nib.instantiate(withOwner: self, options: nil).first as! Self
    }
    
}
