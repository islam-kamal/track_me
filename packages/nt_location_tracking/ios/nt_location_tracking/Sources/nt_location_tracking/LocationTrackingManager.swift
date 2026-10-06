import CoreLocation
import Flutter
import UIKit

final class LocationTrackingManager: NSObject, CLLocationManagerDelegate {
  static let shared = LocationTrackingManager()

  private let locationManager = CLLocationManager()
  private var permissionResult: FlutterResult?

  override private init() {
    super.init()
    locationManager.delegate = self
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false
    locationManager.showsBackgroundLocationIndicator = true
  }

  func requestPermissions(result: @escaping FlutterResult) {
    permissionResult = result
    locationManager.requestAlwaysAuthorization()
  }

  func startTracking() {
    let prefs = TrackingPreferences.shared
    guard prefs.userId != nil else {
      return
    }

    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.distanceFilter = prefs.distanceFilterMeters
    locationManager.startUpdatingLocation()
    locationManager.startMonitoringSignificantLocationChanges()
    prefs.isTracking = true
  }

  func stopTracking() {
    locationManager.stopUpdatingLocation()
    locationManager.stopMonitoringSignificantLocationChanges()
    TrackingPreferences.shared.isTracking = false
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    guard let result = permissionResult else {
      return
    }
    permissionResult = nil

    let status: CLAuthorizationStatus
    if #available(iOS 14.0, *) {
      status = manager.authorizationStatus
    } else {
      status = CLLocationManager.authorizationStatus()
    }

    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      result(true)
    default:
      result(false)
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.last else {
      return
    }

    let prefs = TrackingPreferences.shared
    guard let userId = prefs.userId else {
      return
    }

    if prefs.enableReverseGeocoding {
      AddressGeocoder.reverseGeocode(location: location) { address in
        LocationEventDispatcher.dispatch(
          location,
          address: address
        )
      }
    } else {
      LocationEventDispatcher.dispatch(
        location,
        address: nil
      )
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // Ignore transient location errors.
  }
}
