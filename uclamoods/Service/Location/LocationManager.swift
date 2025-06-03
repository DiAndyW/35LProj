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
    
    private var isProcessingOneTimeFetchWithLandmark: Bool = false
    
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
        isProcessingOneTimeFetchWithLandmark = false
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
        isProcessingOneTimeFetchWithLandmark = false
    }
    
    // Your one-time fetch for landmark (can remain as is if used elsewhere)
    func fetchCurrentLocationAndLandmark() { // Renamed for clarity
        isLoading = true
        isProcessingOneTimeFetchWithLandmark = true
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
            isProcessingOneTimeFetchWithLandmark = false
        @unknown default:
            self.isLoading = false
            isProcessingOneTimeFetchWithLandmark = false
            break
        }
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            // If it was a one-time fetch and we didn't get a location somehow
            if isProcessingOneTimeFetchWithLandmark {
                self.isLoading = false
                isProcessingOneTimeFetchWithLandmark = false
            }
            return
        }
        self.userCoordinates = location.coordinate
        
        self.mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: self.mapRegion.span
        )
        print("LocationManager: Coordinates updated - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
        
        if isProcessingOneTimeFetchWithLandmark {
            // It was a one-time fetch, now get the landmark.
            // fetchLandmark will handle setting isLoading to false and resetting the flag.
            fetchLandmark(for: location)
        }
        // If it's for continuous map updates, isLoading remains true until stopUpdatingMapLocation is called.
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed with error: \(error.localizedDescription)")
        self.landmarkName = "Could not fetch location"
        self.userCoordinates = nil
        self.isLoading = false
        isProcessingOneTimeFetchWithLandmark = false
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
            isProcessingOneTimeFetchWithLandmark = false
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
            
            defer {
                if self.isProcessingOneTimeFetchWithLandmark {
                    self.isLoading = false
                    self.isProcessingOneTimeFetchWithLandmark = false // Reset the flag
                }
            }
            
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
