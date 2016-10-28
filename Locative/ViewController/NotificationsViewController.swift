import NMessenger

class NotificationsViewController: UIViewController {
    
    let bubbleConfiguration = StandardBubbleConfiguration()
    let settings = (UIApplication.shared.delegate as? AppDelegate)?.settings
    let cloudConnect = CloudConnect()
    
    var emptyView: NotificationsEmptyView!
    var messengerView: NMessenger!
    var typingIndicator: GeneralMessengerCell?
    var isReloading = false
    
    @IBOutlet weak var reloadButton: UIBarButtonItem?
    
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
        updateEmptyState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadMessages()
    }
    
    private func updateEmptyState() {
        if let s = settings?.isLoggedIn, !s {
            view.superview?.addSubviewIfNotAdded(emptyView)
        } else {
            guard let superview = view.superview else { return }
            emptyView.removeFromSuperviewIfAdded(superview)
        }
        if let s = settings {
            reloadButton?.isEnabled = s.isLoggedIn
        }
    }
    
    private func showTypingIndicator() {
        let typing = TypingIndicatorContent(bubbleConfiguration: self.bubbleConfiguration)
        typingIndicator = MessageNode(content: typing)
        messengerView.addTypingIndicator(typingIndicator!, scrollsToLast: false, animated: true, completion: nil)
    }
    
    private func hideTypingIndicator() {
        guard let indicator = typingIndicator else { return }
        messengerView.removeTypingIndicator(indicator, scrollsToLast: false, animated: true)
    }
    
    @IBAction func reloadMessages() {
        guard let s = settings, s.isLoggedIn else {
            return
        }
        guard !isReloading else {
            return
        }
        isReloading = true
        messengerView.removeMessages(messengerView.allMessages(), animation: .automatic)
        showTypingIndicator()
        cloudConnect.getLastMessages { [unowned self] messages in
            self.hideTypingIndicator()
            self.isReloading = false
            guard let msgs = messages else {
                return self.addMessage(
                    text: NSLocalizedString("Notifications currently unavailable.", comment: "Notifications currently unavailable.")
                )
            }
            guard !msgs.isEmpty else {
                return self.addMessage(
                    text: NSLocalizedString("You have no notifications.", comment: "You have no notifications.")
                )

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
        newMessage.cellPadding = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        messengerView.addMessage(newMessage, scrollsToMessage: true)
    }
}
