import '../../geocoding/location_geocoder.dart';

/// Cached reverse geocoding for map marker info windows.
///
/// Avoids repeated platform geocode calls when users tap the same markers
/// or when [LocationPoint.address] was already resolved during tracking.
class AddressResolver {
  AddressResolver();

  final Map<String, String> _cache = <String, String>{};

  Future<String?> resolve({
    required double latitude,
    required double longitude,
    String? existingAddress,
  }) async {
    if (existingAddress != null && existingAddress.trim().isNotEmpty) {
      _cache[_cacheKey(latitude, longitude)] = existingAddress;
      return existingAddress;
    }

    final key = _cacheKey(latitude, longitude);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final address = await LocationGeocoder.reverseGeocode(
      latitude: latitude,
      longitude: longitude,
    );
    if (address != null && address.isNotEmpty) {
      _cache[key] = address;
    }
    return address;
  }

  void seed(String? address, {required double latitude, required double longitude}) {
    if (address == null || address.trim().isEmpty) {
      return;
    }
    _cache[_cacheKey(latitude, longitude)] = address;
  }

  void clear() => _cache.clear();

  String _cacheKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
  }
}
