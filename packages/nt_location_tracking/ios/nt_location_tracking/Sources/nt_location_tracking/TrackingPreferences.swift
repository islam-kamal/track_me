import Foundation

final class TrackingPreferences {
  static let shared = TrackingPreferences()
  private let defaults = UserDefaults.standard

  private enum Keys {
    static let isTracking = "location_tracking_is_tracking"
    static let userId = "location_tracking_user_id"
    static let distanceFilter = "location_tracking_distance_filter"
    static let intervalSeconds = "location_tracking_interval_seconds"
    static let enableReverseGeocoding = "location_tracking_enable_reverse_geocoding"
  }

  var isTracking: Bool {
    get { defaults.bool(forKey: Keys.isTracking) }
    set { defaults.set(newValue, forKey: Keys.isTracking) }
  }

  var userId: String? {
    get { defaults.string(forKey: Keys.userId) }
    set { defaults.set(newValue, forKey: Keys.userId) }
  }

  var distanceFilterMeters: Double {
    get {
      let value = defaults.double(forKey: Keys.distanceFilter)
      return value == 0 ? 10 : value
    }
    set { defaults.set(newValue, forKey: Keys.distanceFilter) }
  }

  var intervalSeconds: Int {
    get {
      let value = defaults.integer(forKey: Keys.intervalSeconds)
      return value == 0 ? 30 : value
    }
    set { defaults.set(newValue, forKey: Keys.intervalSeconds) }
  }

  var enableReverseGeocoding: Bool {
    get { defaults.bool(forKey: Keys.enableReverseGeocoding) }
    set { defaults.set(newValue, forKey: Keys.enableReverseGeocoding) }
  }

  func saveConfig(
    userId: String,
    distanceFilterMeters: Double,
    intervalSeconds: Int,
    enableReverseGeocoding: Bool = false
  ) {
    self.userId = userId
    self.distanceFilterMeters = distanceFilterMeters
    self.intervalSeconds = intervalSeconds
    self.enableReverseGeocoding = enableReverseGeocoding
  }
}
