import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safebrowser/features/child/presentation/pages/blocked_page.dart';

void main() {
  group('BlockedPage Widget Tests', () {
    testWidgets('should display friendly UI elements when content is blocked', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MaterialApp(home: BlockedPage()));

      // Verify the main message is displayed.
      expect(find.text('This page was blocked to keep you safe'), findsOneWidget);

      // Verify the friendly shield icon is present, not a harsh warning sign.
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.byIcon(Icons.block), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);

      // Verify the background color is the friendly light blue.
      final Scaffold scaffold = tester.widget(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.lightBlue[100]);

      // Verify the action buttons are present.
      expect(find.widgetWithText(ElevatedButton, 'Go Back'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Learn Something Safe'), findsOneWidget);
    });
  });
}
