import Foundation

final class Debouncer {
    typealias Action = () -> Void

    fileprivate var timer: Timer?
    
    let action: Action
    var isValid: Bool {
        get {
            guard let timer = timer else { return false }
            return timer.isValid
        }
    }
    func cancel() {
        if let timer = timer, timer.isValid {
            timer.invalidate()
        }
    }

    init(_ action: @escaping Action, interval: TimeInterval = 1) {
        self.action = action
        self.timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(Debouncer.fire), userInfo: nil, repeats: false)
    }
    
    @objc fileprivate func fire() {
        self.action()
    }

}
