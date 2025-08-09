//
//  LocationManager.swift
//  App
//
//  Created by joker on 2025-01-13.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    
    static let shared = LocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = true
    }
    
    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.requestAlwaysAuthorization()
    }
    
    func locationUpdates() -> AsyncStream<CLLocation> {
        return AsyncStream { continuation in
            let updates = CLLocationUpdate.liveUpdates()
            Task {
                do {
                    for try await update in updates {
                        if let location = update.location {
                            continuation.yield(location)
                        }
                    }
                } catch {
                    continuation.finish()
                }
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            
        case .notDetermined:
            print("DEBUG: Not determined")
        case .restricted:
            print("DEBUG: Restricted")
        case .denied:
            print("DEBUG: Denied")
        case .authorizedAlways, .authorizedWhenInUse:
            print("DEBUG: Auth always and in use")
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.userLocation = location
    }
}
