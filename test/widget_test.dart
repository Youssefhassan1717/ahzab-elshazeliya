import 'package:flutter_test/flutter_test.dart';
import 'package:ahzab_app/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AhzabApp());
    await tester.pumpAndSettle();

    expect(find.text('أحزاب الإمام الشاذلي'), findsOneWidget);
  });
}
