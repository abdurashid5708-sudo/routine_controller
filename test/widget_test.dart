import 'package:flutter_test/flutter_test.dart';
import 'package:routine_controller/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RoutineControllerApp());
    expect(find.byType(RoutineControllerApp), findsOneWidget);
  });
}
