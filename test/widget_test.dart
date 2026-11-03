import 'package:flutter_test/flutter_test.dart';
import 'package:lib_mgt/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LibraryApp());

    // Verify splash screen displays Library Management System
    expect(find.text('Library Management System'), findsOneWidget);

    // Fast-forward past 3.5s splash
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pumpAndSettle();

    // Verify Login screen
    expect(find.text('Student Login'), findsOneWidget);
  });
}
