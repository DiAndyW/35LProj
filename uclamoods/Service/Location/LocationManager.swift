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
    
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.0689, longitude: -118.4452),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private var isProcessingOneTimeFetchWithLandmark: Bool = false
    private var locationTimer: Timer?
    private let locationTimeout: TimeInterval = 10.0 // 10 second timeout
    
    // Cache recent location to avoid redundant fetches
    private var lastKnownLocation: CLLocation?
    private let locationCacheTimeout: TimeInterval = 300 // 5 minutes
    private var lastLocationTime: Date?
    
    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        
        // Optimize for faster location acquisition
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters // Reduced from Best
        manager.distanceFilter = 100 // Only update if moved 100m
    }
    
    func requestLocationAccessIfNeeded() {
        if authorizationStatus == .notDetermined {
            print("LocationManager: Requesting 'When In Use' authorization.")
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func startUpdatingMapLocation() {
        isProcessingOneTimeFetchWithLandmark = false
        isLoading = true
        print("LocationManager: startUpdatingMapLocation called. Auth status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("LocationManager: Starting continuous location updates for map.")
                manager.startUpdatingLocation()
                startLocationTimeout()
            case .notDetermined:
                print("LocationManager: Authorization not determined. Requesting access.")
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                print("LocationManager: Location access denied or restricted.")
                handleLocationFailure(message: "Location access denied")
            @unknown default:
                handleLocationFailure(message: "Unknown location error")
        }
    }
    
    func stopUpdatingMapLocation() {
        print("LocationManager: Stopping continuous location updates for map.")
        manager.stopUpdatingLocation()
        stopLocationTimeout()
        isLoading = false
        isProcessingOneTimeFetchWithLandmark = false
    }
    
    func fetchCurrentLocationAndLandmark() {
        // Check if we have a recent cached location
        if let cachedLocation = getCachedLocationIfValid() {
            print("LocationManager: Using cached location")
            userCoordinates = cachedLocation.coordinate
            updateMapRegion(for: cachedLocation.coordinate)
            
            // Still fetch landmark for cached location if needed
            if landmarkName == nil || landmarkName == "Fetching location..." {
                fetchLandmark(for: cachedLocation)
            }
            return
        }
        
        isLoading = true
        isProcessingOneTimeFetchWithLandmark = true
        print("LocationManager: Starting fresh location fetch. Auth status: \(authorizationStatus.rawValue)")
        
        switch authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                // Use requestLocation for one-time fetch - it's faster than startUpdatingLocation
                manager.requestLocation()
                startLocationTimeout()
            case .restricted, .denied:
                print("LocationManager: Location access denied or restricted.")
                handleLocationFailure(message: "Location access denied")
            @unknown default:
                handleLocationFailure(message: "Unknown location error")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCachedLocationIfValid() -> CLLocation? {
        guard let lastLocation = lastKnownLocation,
              let lastTime = lastLocationTime,
              Date().timeIntervalSince(lastTime) < locationCacheTimeout else {
            return nil
        }
        return lastLocation
    }
    
    private func startLocationTimeout() {
        stopLocationTimeout() // Clear any existing timer
        locationTimer = Timer.scheduledTimer(withTimeInterval: locationTimeout, repeats: false) { [weak self] _ in
            self?.handleLocationTimeout()
        }
    }
    
    private func stopLocationTimeout() {
        locationTimer?.invalidate()
        locationTimer = nil
    }
    
    private func handleLocationTimeout() {
        print("LocationManager: Location fetch timed out")
        manager.stopUpdatingLocation()
        
        // Use last known location if available
        if let cachedLocation = lastKnownLocation {
            print("LocationManager: Using last known location due to timeout")
            userCoordinates = cachedLocation.coordinate
            updateMapRegion(for: cachedLocation.coordinate)
            landmarkName = "Near your last known location"
        } else {
            handleLocationFailure(message: "Location timeout")
        }
        
        finishLocationFetch()
    }
    
    private func handleLocationFailure(message: String) {
        landmarkName = message
        userCoordinates = nil
        finishLocationFetch()
    }
    
    private func finishLocationFetch() {
        stopLocationTimeout()
        isLoading = false
        isProcessingOneTimeFetchWithLandmark = false
    }
    
    private func updateMapRegion(for coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: mapRegion.span
        )
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            if isProcessingOneTimeFetchWithLandmark {
                finishLocationFetch()
            }
            return
        }
        
        // Cache the location
        lastKnownLocation = location
        lastLocationTime = Date()
        
        userCoordinates = location.coordinate
        updateMapRegion(for: location.coordinate)
        
        print("LocationManager: Coordinates updated - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
        
        if isProcessingOneTimeFetchWithLandmark {
            fetchLandmark(for: location)
        }
        
        // Stop timeout timer since we got a location
        if isProcessingOneTimeFetchWithLandmark {
            stopLocationTimeout()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationManager: Failed with error: \(error.localizedDescription)")
        
        // Try to use cached location if available
        if let cachedLocation = lastKnownLocation {
            print("LocationManager: Using cached location due to error")
            userCoordinates = cachedLocation.coordinate
            updateMapRegion(for: cachedLocation.coordinate)
            landmarkName = "Near your last known location"
        } else {
            handleLocationFailure(message: "Could not fetch location")
        }
        
        finishLocationFetch()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let oldStatus = authorizationStatus
        authorizationStatus = manager.authorizationStatus
        print("LocationManager: Authorization status changed from \(oldStatus.rawValue) to \(authorizationStatus.rawValue)")
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            print("LocationManager: Authorization granted, can now start/continue location updates.")
        } else {
            print("LocationManager: Location authorization not granted (\(authorizationStatus.rawValue)).")
            handleLocationFailure(message: "Location access needed")
        }
    }
    
    private func fetchLandmark(for location: CLLocation) {
        let geocoder = CLGeocoder()
        
        let geocodingTimeout = DispatchWorkItem {
            geocoder.cancelGeocode()
            print("LocationManager: Geocoding timed out, using fallback")
            self.landmarkName = "Near your current location"
            if self.isProcessingOneTimeFetchWithLandmark {
                self.finishLocationFetch()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0, execute: geocodingTimeout)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            geocodingTimeout.cancel()
            
            defer {
                if self.isProcessingOneTimeFetchWithLandmark {
                    self.finishLocationFetch()
                }
            }
            
            if let error = error {
                print("LocationManager: Reverse geocoding failed: \(error.localizedDescription)")
                self.landmarkName = "Near your current location"
                return
            }
            
            if let placemark = placemarks?.first {
                var determinedName: String?
                
                // Priority 1: A non-address-like Point of Interest (e.g., "UCLA", "Apple Park")
                if let name = placemark.name {
                    let startsWithNumber = name.rangeOfCharacter(from: .decimalDigits)?.lowerBound == name.startIndex
                    if !startsWithNumber {
                        determinedName = name
                    }
                }
                
                // Priority 2: Neighborhood (e.g., "Westwood")
                if determinedName == nil, let neighborhood = placemark.subLocality {
                    determinedName = neighborhood
                }
                
                // Priority 3: City (e.g., "Los Angeles")
                if determinedName == nil, let city = placemark.locality {
                    determinedName = city
                }
                
                self.landmarkName = determinedName ?? "Near your current location"
                print("LocationManager: Fetched less precise landmark - \(self.landmarkName ?? "N/A")")
                
            } else {
                self.landmarkName = "Near your current location"
                print("LocationManager: No placemark found.")
            }
        }
    }
}
