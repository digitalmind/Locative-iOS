import Foundation
import ObjectiveRecord

public class CoreDataStack: NSObject {
    let coreDataManager = CoreDataManager.sharedManager()
        
    public init(model: String) {
        super.init()
        coreDataManager.modelName = model
        coreDataManager.bundle = NSBundle(forClass: self.dynamicType)
        migrateDatabase()
        migrateCredentials()
    }
    
    private func migrateDatabase() {
        let fileManager = NSFileManager.defaultManager()
        if let legacyPath = legacyDatabasePath(),
            path = databasePath()
            where fileManager.fileExistsAtPath(path) {
            do {
                try fileManager.copyItemAtPath(legacyPath, toPath: path)
                try fileManager.removeItemAtPath(legacyPath)
            } catch _ {} // TODO: Implement loggin here
        }
    }
    
    private func migrateCredentials() {
        synchronized(self) {
            let geofences = Geofence.all() as! [Geofence]
            geofences.forEach { geofence in
                guard let user = geofence.httpUser,
                    uuid = geofence.uuid else {
                    return
                }
                let credentials = SecureCredentials(service: uuid)
                credentials[user] = geofence.httpPassword
                geofence.save()
            }
            
        }
    }
}

private extension CoreDataStack {
    private func legacyDatabasePath() -> String? {
        guard let url = coreDataManager.applicationSupportDirectory()
            .URLByAppendingPathComponent("Geofancy.sqlite") as? NSURL else { return nil }
        return url.path
    }
    
    private func databasePath() -> String? {
        guard let url = coreDataManager.applicationSupportDirectory()
            .URLByAppendingPathComponent("Locative.sqlite") as? NSURL else { return nil }
        return url.path
    }
}
