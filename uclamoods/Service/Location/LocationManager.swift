//
//  LocationManager.swift
//  uclamoods
//
//  Created by David Sun on 6/2/25. // Or your name/current date
//

import SwiftUI
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

@MainActor // Ensure UI updates are on the main thread
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var userCoordinates: CLLocationCoordinate2D?
    @Published var landmarkName: String? // This will store the name of the landmark/address
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isLoading: Bool = false // To indicate when fetching location/landmark

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // Good for landmarks
    }

    func requestLocationAccess() {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func startFetchingLocation() {
        isLoading = true
        print("LocationManager: Starting to fetch location. Auth status: \(authorizationStatus.rawValue)")
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
        guard let location = locations.first else {
            isLoading = false
            return
        }
        self.userCoordinates = location.coordinate
        print("LocationManager: Coordinates updated - Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
        fetchLandmark(for: location) // fetchLandmark will set isLoading = false when done
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
             // If status just changed to authorized, fetch location
            if oldStatus == .notDetermined { // Only auto-fetch if it was 'notDetermined' before
                 print("LocationManager: Authorization granted, now fetching location.")
                 startFetchingLocation()
            }
        } else {
            print("LocationManager: Location authorization not granted (\(authorizationStatus.rawValue)).")
            self.landmarkName = "Location access needed"
            self.userCoordinates = nil
            self.isLoading = false
        }
    }

    // MARK: - Reverse Geocoding

    private func fetchLandmark(for location: CLLocation) {
        let geocoder = CLGeocoder()
        // isLoading is already true from startFetchingLocation or didUpdateLocations
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            defer { self.isLoading = false } // Ensure isLoading is set to false in all exit paths

            if let error = error {
                print("LocationManager: Reverse geocoding failed: \(error.localizedDescription)")
                self.landmarkName = "Nearby your location" // Fallback
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
