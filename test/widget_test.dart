import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/app/app.dart';
import 'package:flow_day/core/providers/database_providers.dart';

void main() {
  testWidgets('FlowDayApp boots and displays 4 bottom navigation tabs when onboarding is completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FlowDayApp(),
      ),
    );

    // Allow splash timer to complete and route to /home
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify all 4 tab buttons exist in bottom nav bar
    expect(find.byKey(const ValueKey('tab_home')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_schedule')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_insights')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_settings')), findsOneWidget);

    // Verify initial home screen content
    expect(find.text('Daily Command Center (Screen 07)'), findsOneWidget);
    expect(find.text('Open Design Gallery (/dev/components)'), findsOneWidget);
    expect(find.text('Open Database Test (/dev/database)'), findsOneWidget);

    // Switch to Schedule tab
    await tester.tap(find.byKey(const ValueKey('tab_schedule')));
    await tester.pumpAndSettle();
    expect(find.text('Daily Timeline & Agenda (Screen 08)'), findsOneWidget);

    // Switch to Insights tab
    await tester.tap(find.byKey(const ValueKey('tab_insights')));
    await tester.pumpAndSettle();
    expect(find.text('Productivity & Habits (Screen 23)'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.byKey(const ValueKey('tab_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Preferences & Schedule (Screen 24)'), findsOneWidget);
  });
}
