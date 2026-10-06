/// Backend-independent exception hierarchy.
///
/// Adapter packages (Firebase, REST) map their SDK errors to these types
/// so the core plugin and host app handle failures consistently.

/// Base exception for location tracking failures.
class TrackingException implements Exception {
  const TrackingException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'TrackingException: $message';
    }
    return 'TrackingException: $message ($cause)';
  }
}

/// Backend rejected the request (invalid token, Firebase rules, etc.).
class AuthenticationException extends TrackingException {
  const AuthenticationException(super.message, {super.cause});
}

/// Connectivity failure or unreachable backend.
class NetworkException extends TrackingException {
  const NetworkException(super.message, {super.cause});
}
