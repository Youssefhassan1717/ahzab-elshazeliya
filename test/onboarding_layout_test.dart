import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ahzab_app/screens/onboarding/onboarding_screen.dart';

/// Renders every onboarding page at a few screen sizes. Any overflow or paint
/// error surfaces as a test failure.
Future<void> _walkAllPages(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const MaterialApp(home: OnboardingScreen(), debugShowCheckedModeBanner: false),
  );
  await tester.pump(const Duration(milliseconds: 300));

  // Five taps walks pages 1..6; the sixth would navigate away to the home screen.
  for (var i = 0; i < 5; i++) {
    expect(tester.takeException(), isNull, reason: 'page $i at $size');
    expect(
      find.byType(SingleChildScrollView),
      findsNothing,
      reason: 'page $i at $size should fit without scrolling',
    );
    await tester.tap(find.text('التالي'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }
  expect(tester.takeException(), isNull, reason: 'last page at $size');

  await tester.pumpWidget(const SizedBox());
}

void main() {
  testWidgets('onboarding fits a small phone', (tester) async {
    await _walkAllPages(tester, const Size(320, 568));
  });

  testWidgets('onboarding fits a typical phone', (tester) async {
    await _walkAllPages(tester, const Size(411, 915));
  });

  testWidgets('onboarding fits a tablet', (tester) async {
    await _walkAllPages(tester, const Size(800, 1280));
  });
}
