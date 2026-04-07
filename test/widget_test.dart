import 'package:flutter_test/flutter_test.dart';
import 'package:focus_life/main.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(permissionShown: false));
  });
}