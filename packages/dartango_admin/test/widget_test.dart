// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:dartango_admin/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts with login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DartangoAdminApp());

    // Verify that the login screen is displayed.
    expect(find.text('Dartango Admin'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}
