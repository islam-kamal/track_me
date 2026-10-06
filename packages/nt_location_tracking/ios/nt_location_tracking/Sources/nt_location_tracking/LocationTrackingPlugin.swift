import CoreLocation
import Flutter
import UIKit

public class LocationTrackingPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "nt_location_tracking",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "nt_location_tracking/events",
      binaryMessenger: registrar.messenger()
    )
    let instance = LocationTrackingPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      guard let args = call.arguments as? [String: Any],
            let userId = args["userId"] as? String else {
        result(FlutterError(code: "invalid_args", message: "Config map is required", details: nil))
        return
      }
      let distanceFilter = (args["distanceFilterMeters"] as? NSNumber)?.doubleValue ?? 10
      let intervalSeconds = (args["intervalSeconds"] as? NSNumber)?.intValue ?? 30
      let enableReverseGeocoding = args["enableReverseGeocoding"] as? Bool ?? false
      TrackingPreferences.shared.saveConfig(
        userId: userId,
        distanceFilterMeters: distanceFilter,
        intervalSeconds: intervalSeconds,
        enableReverseGeocoding: enableReverseGeocoding
      )
      result(nil)

    case "startTracking":
      LocationTrackingManager.shared.startTracking()
      result(nil)

    case "stopTracking":
      LocationTrackingManager.shared.stopTracking()
      result(nil)

    case "isTracking":
      result(TrackingPreferences.shared.isTracking)

    case "getCurrentLocation":
      guard let location = LocationEventDispatcher.getLatestLocation() else {
        result(nil)
        return
      }
      result(location.toPayload(isMoving: true))

    case "requestPermissions":
      LocationTrackingManager.shared.requestPermissions(result: result)

    case "openBatteryOptimizationSettings":
      result(false)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    LocationEventDispatcher.setEventSink { payload in
      events(payload)
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    LocationEventDispatcher.setEventSink(nil)
    return nil
  }
}
