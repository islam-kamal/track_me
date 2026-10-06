import CoreLocation
import Foundation

enum LocationEventDispatcher {
  private static var eventSink: (([String: Any]) -> Void)?
  private static var latestLocation: CLLocation?

  static func setEventSink(_ sink: (([String: Any]) -> Void)?) {
    eventSink = sink
  }

  static func dispatch(
    _ location: CLLocation,
    isMoving: Bool = true,
    address: String? = nil
  ) {
    latestLocation = location
    let payload = location.toPayload(isMoving: isMoving, address: address)
    eventSink?(payload)
  }

  static func getLatestLocation() -> CLLocation? {
    latestLocation
  }
}
