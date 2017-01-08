import Foundation
import Alamofire

struct Message {
    let text: String
}

class CloudConnect {
    
    struct AccountData {
        let username: String
        let email: String
        let avatarUrl: String
        
        func toPlist() -> [String: String] {
            return [
                "username": username,
                "email": email,
                "avatarUrl": avatarUrl
            ]
        }
    }
    
    let settings = Settings()
    
    class var backendProtocol: String {
        return Bundle.main.infoDictionary!["BackendProtocol"] as! String
    }
    
    class var backendHost: String {
        return Bundle.main.infoDictionary!["BackendHost"] as! String
    }
    
    class var cloudUrl: String {
        return "\(backendProtocol)://\(backendHost)"
    }

    func getLastMessages(_ completion: @escaping ([Message]?) -> Void) {
        guard let sessionId = settings.apiToken else {
            return completion([])
        }
        Alamofire.request("\(CloudConnect.cloudUrl)/api/notifications", parameters: [
            "sessionId": sessionId
        ]).responseJSON { response in
            guard let json = response.result.value as? [String: Any] else {
                return completion([])
            }
            completion((json["notifications"] as! [[String: Any]]).map {
                return Message(text: $0["message"] as! String)
            })
        }
    }
    
    func getAccountData(_ completion: @escaping (AccountData?) -> Void) {
        guard let sessionId = settings.apiToken else {
            return completion(nil)
        }
        Alamofire.request("\(CloudConnect.cloudUrl)/api/account", parameters: [
            "sessionId": sessionId
        ]).responseJSON { response in
            guard let json = response.result.value as? [String: String] else {
                return completion(nil)
            }
            completion(
                AccountData(
                    username: json["username"] ?? "Unknown".localized(),
                    email: json["email"] ?? "Unknown".localized(),
                    avatarUrl: json["avatarUrl"] ?? ""
                )
            )
        }
    }
}
