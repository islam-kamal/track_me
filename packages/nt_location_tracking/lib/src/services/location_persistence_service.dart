import 'dart:async';

import '../contracts/location_storage_data_source.dart';
import '../exceptions/tracking_exception.dart';
import '../models/location_point.dart';

/// Business layer between the location stream and backend storage.
///
/// Exists so platform trackers stay unaware of Firebase/REST and so errors
/// from any backend are normalized to [TrackingException] subclasses.
class LocationPersistenceService {
  LocationPersistenceService({
    required LocationStorageDataSource storage,
    required String subjectId,
  })  : _storage = storage,
        _subjectId = subjectId;

  final LocationStorageDataSource _storage;
  final String _subjectId;

  Future<void> persist(LocationPoint point) async {
    try {
      await _storage.saveLocation(point, subjectId: _subjectId);
    } on TrackingException {
      rethrow;
    } catch (error) {
      // Wrap unknown adapter/network failures in a consistent exception type.
      throw NetworkException(
        'Failed to save location.',
        cause: error,
      );
    }
  }
}
