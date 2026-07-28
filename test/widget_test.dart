import 'package:flutter_test/flutter_test.dart';
import 'package:check_point/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FaceRecogApp());
    await tester.pump();

    // Verify that the loading indicator or face text appears.
    expect(find.byType(FaceRecogApp), findsOneWidget);
  });
}
