/// Realtime Database targets for the Track Me project.
///
/// Default Realtime Database for project track-me-8e64a.
///
/// This project is on the Spark plan, which allows only one database instance.
/// Profiles, the admin allowlist, and location history all use this URL,
/// including saves made after the app is terminated. The instance is not deleted.
const String legacyDatabaseUrl =
    'https://track-me-8e64a-default-rtdb.firebaseio.com';

const String trackingDatabaseUrl = legacyDatabaseUrl;
