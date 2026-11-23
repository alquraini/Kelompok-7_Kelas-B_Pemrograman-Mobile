import 'package:flutter_test/flutter_test.dart';
import 'package:split_bill_app/main.dart';

void main() {
  testWidgets('SplitBillApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SplitBillApp());
    expect(find.text('Login - Split Bill'), findsOneWidget);
  });
}