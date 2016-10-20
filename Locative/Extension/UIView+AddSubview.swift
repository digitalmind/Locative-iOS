extension UIView {
    func addSubviewIfNotAdded(_ subview: UIView) {
        if !subview.isDescendant(of: self) {
            self.addSubview(subview)
        }
    }
    
    func removeFromSuperviewIfAdded(_ to: UIView) {
        if self.isDescendant(of: to) {
            self.removeFromSuperview()
        }
    }
}
