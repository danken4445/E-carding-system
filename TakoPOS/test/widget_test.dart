import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/app.dart';

void main() {
  testWidgets('TakoPOS app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: TakoPOSApp(),
      ),
    );

    // Verify that the app starts and shows the TakoPOS title
    expect(find.text('TakoPOS'), findsOneWidget);
  });
}
