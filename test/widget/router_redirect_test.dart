import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/app/app.dart';
import 'package:flow_day/app/router/app_router.dart';
import 'package:flow_day/core/providers/database_providers.dart';

void main() {
  testWidgets('Splash redirects to /onboarding/1 when onboardingDone is false', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();

    appRouter.go('/splash');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FlowDayApp(),
      ),
    );

    // Initial splash state
    expect(find.text('Make time for what matters.'), findsOneWidget);

    // Allow splash timer (1400ms) to complete and route
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify redirected to Intro screen 02 (/onboarding/1)
    expect(find.textContaining('Plan your day'), findsOneWidget);
    expect(find.text('Next ->'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Verify NOT on Home screen
    expect(find.text('Daily Command Center (Screen 07)'), findsNothing);
  });

  testWidgets('Splash redirects to /home when onboardingDone is true', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();

    appRouter.go('/splash');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FlowDayApp(),
      ),
    );

    // Allow splash timer to complete and route
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify redirected directly to /home
    expect(find.text('Daily Command Center (Screen 07)'), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_home')), findsOneWidget);

    // Verify NOT on Intro screens
    expect(find.textContaining('Plan your day'), findsNothing);
  });
}
