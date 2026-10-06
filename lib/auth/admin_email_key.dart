/// Realtime Database key for an admin email.
///
/// `.` is not used in the key because security rules look up
/// `admins/{email-with-commas}`.
String adminEmailKey(String email) {
  return email.trim().toLowerCase().replaceAll('.', ',');
}
