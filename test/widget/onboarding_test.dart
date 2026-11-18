import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/features/onboarding/presentation/intro_screen.dart';
import 'package:flow_day/features/onboarding/presentation/personalize_screen.dart';

void main() {
  testWidgets('IntroScreen pager navigates across all 3 slides', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IntroScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Page 1
    expect(find.textContaining('Plan your day'), findsOneWidget);
    expect(find.text('Next ->'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Next -> to Page 2
    await tester.tap(find.text('Next ->'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Stay on track'), findsOneWidget);
    expect(find.text('Next ->'), findsOneWidget);

    // Tap Next -> to Page 3
    await tester.tap(find.text('Next ->'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plans change'), findsOneWidget);
    expect(find.text('Get Started ->'), findsOneWidget);
  });

  testWidgets('PersonalizeScreen validates required name and renders defaults', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: PersonalizeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and required empty name field
    expect(find.text("Let's personalize\nyour flow ✨"), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);

    // Green check should NOT be present initially
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    // Tap Continue without entering name -> shows validation error
    final continueButton = find.text('Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name to personalize your schedule.'), findsOneWidget);

    // Enter name
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pumpAndSettle();

    // Green check should now be visible
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Verify defaults
    expect(find.text('07:00 AM'), findsOneWidget); // Wake-up
    expect(find.text('11:00 PM'), findsOneWidget); // Sleep
    expect(find.text('09:30 PM'), findsOneWidget); // Nightly review
    expect(find.text('Soft Chime'), findsOneWidget); // Notification sound
    expect(find.text('15m'), findsOneWidget); // Default break
  });
}
