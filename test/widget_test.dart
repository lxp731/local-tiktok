import 'package:flutter_test/flutter_test.dart';

import 'package:local_tok/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalTokApp());
    // Basic smoke test — the home screen should render without crashing
    expect(find.byType(LocalTokApp), findsOneWidget);
  });
}
