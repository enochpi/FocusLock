import 'package:flutter_test/flutter_test.dart';
import 'package:berry_focused/main.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(permissionShown: false));
  });
}