import 'package:flutter_test/flutter_test.dart';
import 'package:sub2admin/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(Sub2AdminApp());
    expect(find.byType(Sub2AdminApp), findsOneWidget);
  });
}
