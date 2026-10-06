import CoreLocation
import Foundation

enum AddressGeocoder {
  static func reverseGeocode(
    location: CLLocation,
    completion: @escaping (String?) -> Void
  ) {
    CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
      guard let placemark = placemarks?.first else {
        completion(nil)
        return
      }
      completion(format(placemark))
    }
  }

  private static func format(_ placemark: CLPlacemark) -> String? {
    let parts = [
      placemark.name,
      placemark.thoroughfare,
      placemark.locality,
      placemark.administrativeArea,
      placemark.country,
    ].compactMap { value -> String? in
      guard let value, !value.isEmpty else {
        return nil
      }
      return value
    }

    if parts.isEmpty {
      return nil
    }
    return parts.joined(separator: ", ")
  }
}
