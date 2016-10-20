import UIKit

class EmptyView: UIView {
    
    var buttonAction: ((_ button: UIButton) -> Void)?
    
    @IBOutlet weak fileprivate var label: UILabel!
    @IBOutlet weak fileprivate var button: UIButton!
    
    @IBAction fileprivate func buttonPressed(sender: UIButton) {
        if let action = buttonAction {
            action(sender)
        }
    }
}
