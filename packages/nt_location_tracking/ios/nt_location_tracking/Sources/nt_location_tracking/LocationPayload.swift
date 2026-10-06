import CoreLocation
import Foundation

enum LocationTimestampFormatter {
  private static let formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
  }()

  static func string(from date: Date) -> String {
    formatter.string(from: date)
  }
}

extension CLLocation {
  func toPayload(isMoving: Bool, address: String? = nil) -> [String: Any] {
    var payload: [String: Any] = [
      "latitude": coordinate.latitude,
      "longitude": coordinate.longitude,
      "accuracy": horizontalAccuracy,
      "altitude": altitude,
      "speed": speed,
      "heading": course,
      "timestamp": LocationTimestampFormatter.string(from: timestamp),
      "platform": "ios",
      "isMoving": isMoving,
    ]
    if let address, !address.isEmpty {
      payload["address"] = address
    }
    return payload
  }
}
