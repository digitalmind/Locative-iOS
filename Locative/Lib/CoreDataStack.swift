import Foundation
import ObjectiveRecord

open class CoreDataStack: NSObject {
    let coreDataManager = CoreDataManager.shared()
        
    public init(model: String) {
        super.init()
        coreDataManager?.modelName = model
        coreDataManager?.bundle = Bundle(for: type(of: self))
        migrateDatabase()
        migrateCredentials()
    }
    
    fileprivate func migrateDatabase() {
        let fileManager = FileManager.default
        if let legacyPath = legacyDatabasePath(),
            let path = databasePath()
            , fileManager.fileExists(atPath: path) {
            do {
                try fileManager.copyItem(atPath: legacyPath, toPath: path)
                try fileManager.removeItem(atPath: legacyPath)
            } catch _ {} // TODO: Implement loggin here
        }
    }
    
    fileprivate func migrateCredentials() {
        synchronized(self) {
            let geofences = Geofence.all() as! [Geofence]
            geofences.forEach { geofence in
                guard let user = geofence.httpUser,
                    let uuid = geofence.uuid else {
                    return
                }
                let credentials = SecureCredentials(service: uuid)
                if let password = geofence.httpPassword {
                    credentials[user] = password
                }
                geofence.save()
            }
            
        }
    }
}

private extension CoreDataStack {
    func legacyDatabasePath() -> String? {
        guard let url = coreDataManager?.applicationSupportDirectory()
            .appendingPathComponent("Geofancy.sqlite") else { return nil }
        return url.path
    }
    
    func databasePath() -> String? {
        guard let url = coreDataManager?.applicationSupportDirectory()
            .appendingPathComponent("Locative.sqlite") else { return nil }
        return url.path
    }
}
