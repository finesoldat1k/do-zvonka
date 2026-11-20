// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';

import 'package:do_zvonka/main.dart';

void main() {
  testWidgets('App starts and shows initial screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoZvonkaApp());

    // Verify that the app title is shown
    expect(find.text('до звонка'), findsOneWidget);
  });
}