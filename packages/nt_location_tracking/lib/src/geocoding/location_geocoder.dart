import 'package:geocoding/geocoding.dart';

/// Reverse geocoding for tracked locations using platform APIs.
///
/// Used when saving locations (iOS tracker) and when resolving marker addresses.
/// Failures return null instead of throwing — geocoding is best-effort.
class LocationGeocoder {
  const LocationGeocoder._();

  static Future<String?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        return null;
      }
      return _formatPlacemark(placemarks.first);
    } catch (_) {
      return null;
    }
  }

  static String? _formatPlacemark(Placemark placemark) {
    final parts = <String>[];
    void add(String? value) {
      if (value != null && value.isNotEmpty) {
        parts.add(value);
      }
    }

    add(placemark.name);
    add(placemark.street);
    add(placemark.locality);
    add(placemark.administrativeArea);
    add(placemark.country);

    if (parts.isEmpty) {
      return null;
    }
    return parts.join(', ');
  }
}
