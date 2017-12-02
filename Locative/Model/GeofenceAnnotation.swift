import MapKit

class GeofenceAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D

    @objc init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
