import 'package:flutter/material.dart';

import '../models/map_marker_data.dart';

/// Bottom sheet shown when a map marker is tapped.
///
/// Displays resolved address (or coordinates) without coupling map providers
/// to app-specific navigation.
Future<void> showMarkerDetailsSheet(
  BuildContext context, {
  required MapMarkerData marker,
  required String? address,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marker.isCurrent ? 'Current location' : 'Tracked location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Address',
              value: address?.trim().isNotEmpty == true
                  ? address!
                  : 'Address unavailable',
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Latitude',
              value: marker.latitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Longitude',
              value: marker.longitude.toStringAsFixed(6),
            ),
          ],
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}
