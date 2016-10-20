import Foundation
import Alamofire

struct Message {
    let text: String
}

class CloudConnect {
    
    let settings = Settings()
    
    fileprivate func cloudUrl() -> String {
        return "\(Bundle.main.infoDictionary!["BackendProtocol"]!)://\(Bundle.main.infoDictionary!["BackendHost"]!)"
    }

    func getLastMessages(_ completion: @escaping ([Message]?) -> Void) {
        guard let sessionId = settings.apiToken else {
            return completion([])
        }
        Alamofire.request("\(cloudUrl())/api/notifications", parameters: [
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
}
