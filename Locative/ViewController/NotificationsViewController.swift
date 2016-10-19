import NMessenger

class NotificationsViewController: UIViewController {
    
    let bubbleConfiguration = StandardBubbleConfiguration()
    let settings = Settings()
    let cloudConnect = CloudConnect()
    
    var emptyView: NotificationsEmptyView!
    var messengerView: NMessenger!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        
        emptyView = .loadFromNib()
        emptyView.frame = frame
        emptyView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        emptyView.buttonAction = { [weak self] button in
            self?.tabBarController?.selectedIndex = .settingsIndex
        }
        
        messengerView = NMessenger(frame: frame)
        messengerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(messengerView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !settings.isLoggedIn {
            view.addSubviewIfNotAdded(emptyView)
        } else {
            emptyView.removeFromSuperviewIfAdded(view)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadMessages()
    }
    
    func reloadMessages() {
        guard settings.isLoggedIn else {
            return
        }
        messengerView.removeMessages(messengerView.allMessages(), animation: .automatic)
        cloudConnect.getLastMessages { [unowned self] messages in
            guard let msgs = messages else {
                return self.addMessage(text: "No messages available.")
            }
            guard !msgs.isEmpty else {
                return self.addMessage(text: "You have no messages.")
            }
            msgs.forEach {
                self.addMessage(text: $0.text)
            }
        }
    }
    
    func addMessage(text: String) {
        let textContent = TextContentNode(
            textMessageString: text,
            currentViewController: self,
            bubbleConfiguration: bubbleConfiguration
        )
        let newMessage = MessageNode(content: textContent)
        newMessage.isIncomingMessage = true
        messengerView.addMessage(newMessage, scrollsToMessage: true)
    }
}

fileprivate extension UIView {
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
