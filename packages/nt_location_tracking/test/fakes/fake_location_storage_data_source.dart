import 'package:nt_location_tracking/nt_location_tracking.dart';

/// In-memory fake for unit tests.
class FakeLocationStorageDataSource implements LocationStorageDataSource {
  final savedLocations = <LocationPoint>[];
  String? lastSubjectId;

  @override
  Future<void> saveLocation(
    LocationPoint point, {
    required String subjectId,
  }) async {
    lastSubjectId = subjectId;
    savedLocations.add(point);
  }
}
