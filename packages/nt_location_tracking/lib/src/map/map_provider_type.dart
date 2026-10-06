/// Map rendering backends supported by [LocationTrackingMap].
///
/// Extend this enum + add a [TrackingMapProvider] implementation to support
/// additional vendors (Mapbox, HERE, etc.) without changing host app code.
enum MapProviderType {
  google,
  openStreetMap,
}
