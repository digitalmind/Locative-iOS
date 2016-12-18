import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var onLocationUpdated: OnLocationUpdated
    
    init(onLocation: @escaping OnLocationUpdated) {
        onLocationUpdated = onLocation
        super.init()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
}

extension LocationManager {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        onLocationUpdated(locations.first)
        manager.stopUpdatingLocation()
    }
}
