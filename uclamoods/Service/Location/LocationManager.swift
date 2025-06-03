import SwiftUI
import CoreLocation
import MapKit

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userCoordinates: CLLocationCoordinate2D?
    @Published var landmarkName: String?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isLoading: Bool = false
    
    // For MapView to observe and react to region changes initiated by location updates
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452), // Default (e.g., UCLA)
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest // Changed for better map tracking
    }

    func requestLocationAccessIfNeeded() { // Renamed for clarity
        if authorizationStatus == .notDetermined {
            print("LocationManager: Requesting 'When In Use' authorization.")
            manager.requestWhenInUseAuthorization()
        }
    }

    // Call this when the MapView appears and needs continuous updates
    func startUpdatingMapLocation() {
        isLoading = true // Indicate activity
        print("LocationManager: startUpdatingMapLocation called. Auth status: \(authorizationStatus.rawValue)")
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: Starting continuous location updates for map.")
            manager.startUpdatingLocation()
        case .notDetermined:
            print("LocationManager: Authorization not determined. Requesting access.")
            manager.requestWhenInUseAuthorization() // Will trigger didChangeAuthorization
        case .restricted, .denied:
            print("LocationManager: Location access denied or restricted. Cannot start map updates.")
            self.landmarkName = "Location access denied" // Keep existing behavior
            self.userCoordinates = nil
            self.isLoading = false
        @unknown default:
            self.isLoading = false
            break
        }
    }

    // Call this when the MapView disappears
    func stopUpdatingMapLocation() {
        print("LocationManager: Stopping continuous location updates for map.")
        manager.stopUpdatingLocation()
        isLoading = false // No longer actively fetching
    }
    
    // Your one-time fetch for landmark (can remain as is if used elsewhere)
    func fetchCurrentLocationAndLandmark() { // Renamed for clarity
        isLoading = true
        print("LocationManager: Starting to fetch one-time location and landmark. Auth status: \(authorizationStatus.rawValue)")
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation() // For a one-time location update
        case .restricted, .denied:
            print("LocationManager: Location access denied or restricted.")
            self.landmarkName = "Location access denied"
            self.userCoordinates = nil
            self.isLoading = false
        @unknown default:
            self.isLoading = false
            break
        }
    }

    // MARK: - CLLocationManagerDelegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            // isLoading = false; //isLoading will be set by stopUpdatingMapLocation or fetchLandmark
            return
        }
        self.userCoordinates = location.coordinate
        
        // Update mapRegion to center on the new user location
        // This allows the MapView to bind to a region that automatically follows the user
        self.mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: self.mapRegion.span // Keep existing span or set a new default zoom
        )
        
        print("LocationManager: Coordinates updated - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
        
        // Decide if reverse geocoding is needed based on context.
        // For continuous map updates, you might not want to geocode every single update.
        // For now, let's assume the landmark is fetched if some other logic needs it,
        // or if it was a one-time request.
        // fetchLandmark(for: location) // This would make it geocode on every update.
        
        // If this was a one-time request (e.g., from fetchCurrentLocationAndLandmark),
        // then fetchLandmark would handle isLoading.
        // If it's from startUpdatingMapLocation, isLoading should remain true until stopUpdatingMapLocation.
        // For simplicity now, fetchLandmark sets isLoading to false. If startUpdating is used,
        // the view using it might need to manage its own loading state or we adjust this.
        // For the map, isLoading can be true while it's actively trying to update.
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed with error: \(error.localizedDescription)")
        self.landmarkName = "Could not fetch location"
        self.userCoordinates = nil
        self.isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        authorizationStatus = manager.authorizationStatus
        print("LocationManager: Authorization status changed from \(oldStatus.rawValue) to \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // If status just changed to authorized, and we intended to start map updates:
             print("LocationManager: Authorization granted, can now start/continue location updates.")
             // The view (e.g. MapView on appear) should decide whether to start updates.
             // Or, if a request was pending:
             // startUpdatingMapLocation() // Or fetchCurrentLocationAndLandmark()
        } else {
            print("LocationManager: Location authorization not granted (\(authorizationStatus.rawValue)).")
            self.landmarkName = "Location access needed"
            self.userCoordinates = nil
            self.isLoading = false
        }
    }

    // Your fetchLandmark function remains the same, it's good for getting landmark names.
    // It sets isLoading = false, which is fine for one-time fetches.
    // For continuous updates, the MapView's loading state might be managed separately
    // or tied to whether the locationManager is actively updating.
    private func fetchLandmark(for location: CLLocation) {
        let geocoder = CLGeocoder()
        // isLoading should ideally be true when starting this.
        // If called from didUpdateLocations during continuous updates, this could be frequent.
        // For SnapMap, we primarily need coordinates.
        // self.isLoading = true; // Ensure it's true before geocoding
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            defer { self.isLoading = false }

            if let error = error {
                print("LocationManager: Reverse geocoding failed: \(error.localizedDescription)")
                self.landmarkName = "Nearby your location"
                return
            }

            if let placemark = placemarks?.first {
                var nameComponents: [String] = []
                
                if let poiName = placemark.name, poiName != "\(location.coordinate.latitude),\(location.coordinate.longitude)" {
                    nameComponents.append(poiName)
                } else {
                    if let street = placemark.thoroughfare {
                        var streetAddress = street
                        if let subThoroughfare = placemark.subThoroughfare {
                            streetAddress = "\(subThoroughfare) \(street)"
                        }
                        nameComponents.append(streetAddress)
                    }
                    if let city = placemark.locality, nameComponents.isEmpty {
                        nameComponents.append(city)
                    }
                }
                
                if nameComponents.isEmpty {
                    if let areaOfInterest = placemark.areasOfInterest?.first {
                        nameComponents.append(areaOfInterest)
                    } else if let locality = placemark.locality {
                        nameComponents.append(locality)
                    } else {
                        nameComponents.append("Unnamed Location")
                    }
                }
                self.landmarkName = nameComponents.joined(separator: ", ")
                print("LocationManager: Fetched landmark - \(self.landmarkName ?? "N/A")")
            } else {
                self.landmarkName = "Unknown Location"
                print("LocationManager: No placemark found.")
            }
        }
    }
}
