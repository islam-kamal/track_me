import 'package:flutter_test/flutter_test.dart';
import 'package:nt_location_tracking/nt_location_tracking.dart';

void main() {
  group('MapConfiguration', () {
    test('disables Google Maps without API key', () {
      const config = MapConfiguration(
        enableGoogleMaps: true,
        enableOpenStreetMap: true,
      );

      expect(config.isGoogleMapsAvailable, isFalse);
      expect(config.isOpenStreetMapAvailable, isTrue);
      expect(config.showMapSection, isTrue);
      expect(config.resolvedDefaultProvider, MapProviderType.openStreetMap);
    });

    test('hides map section when both providers disabled', () {
      const config = MapConfiguration(
        enableGoogleMaps: false,
        enableOpenStreetMap: false,
      );

      expect(config.showMapSection, isFalse);
      expect(config.availableProviders, isEmpty);
      expect(config.resolvedDefaultProvider, isNull);
    });

    test('supports Google Maps only', () {
      const config = MapConfiguration(
        googleMapsApiKey: 'test-key',
        enableGoogleMaps: true,
        enableOpenStreetMap: false,
        defaultProvider: MapProviderType.google,
      );

      expect(config.isGoogleMapsAvailable, isTrue);
      expect(config.isOpenStreetMapAvailable, isFalse);
      expect(config.availableProviders, [MapProviderType.google]);
      expect(config.resolvedDefaultProvider, MapProviderType.google);
    });
  });
}
