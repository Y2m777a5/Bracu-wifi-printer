import 'package:flutter_test/flutter_test.dart';
import 'package:bracu_wifi_printer/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const BracuPrintApp());
    expect(find.byType(BracuPrintApp), findsOneWidget);
  });
}