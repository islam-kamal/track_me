import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:track_me/app.dart';

void main() {
  testWidgets('shows Firebase setup until the app is configured', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TrackMeApp());
    expect(find.text('Connect Firebase'), findsOneWidget);
    expect(find.textContaining('track-me-8e64a-default-rtdb'), findsWidgets);
  });
}
