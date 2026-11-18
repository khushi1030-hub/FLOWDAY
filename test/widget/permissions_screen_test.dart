import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/features/onboarding/presentation/permissions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget buildTestWidget({
    required SharedPreferences prefs,
    required List<String> navigatedRoutes,
  }) {
    final testRouter = GoRouter(
      initialLocation: '/onboarding/permissions',
      routes: [
        GoRoute(
          path: '/onboarding/permissions',
          builder: (context, state) => const PermissionsScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedRoutes.add('/home');
            return const Scaffold(body: Text('Home Screen'));
          },
        ),
        GoRoute(
          path: '/onboarding/personalize',
          builder: (context, state) => const Scaffold(body: Text('Personalize Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(
        routerConfig: testRouter,
      ),
    );
  }

  testWidgets('Denied notification permission still marks onboardingDone=true and navigates to /home', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();
    final navigatedRoutes = <String>[];

    // Mock PermissionStatus.denied (0 in permission_handler)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        return {17: 0};
      }
      return null;
    });

    await tester.pumpWidget(buildTestWidget(prefs: prefs, navigatedRoutes: navigatedRoutes));
    await tester.pumpAndSettle();

    expect(find.text('Never miss an\nimportant moment.'), findsOneWidget);
    final enableBtn = find.textContaining('Enable Notifications');
    expect(enableBtn, findsOneWidget);

    // Tap Enable Notifications
    await tester.ensureVisible(enableBtn);
    await tester.tap(enableBtn);
    await tester.pumpAndSettle();

    // Verify onboardingDone is true in preferences
    expect(prefs.getBool('onboarding_done'), isTrue);

    // Verify navigation to /home without throwing
    expect(navigatedRoutes, contains('/home'));
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('Permanently denied permission still marks onboardingDone=true and navigates to /home', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();
    final navigatedRoutes = <String>[];

    // Mock PermissionStatus.permanentlyDenied (2 in permission_handler)
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        return {17: 2};
      }
      return null;
    });

    await tester.pumpWidget(buildTestWidget(prefs: prefs, navigatedRoutes: navigatedRoutes));
    await tester.pumpAndSettle();

    final enableBtn = find.textContaining('Enable Notifications');
    await tester.ensureVisible(enableBtn);
    await tester.tap(enableBtn);
    await tester.pumpAndSettle();

    // Verify onboardingDone is true
    expect(prefs.getBool('onboarding_done'), isTrue);
    expect(navigatedRoutes, contains('/home'));
    expect(find.text('Home Screen'), findsOneWidget);
  });

  testWidgets('Skip for now marks onboardingDone=true and navigates to /home', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': false});
    final prefs = await SharedPreferences.getInstance();
    final navigatedRoutes = <String>[];

    await tester.pumpWidget(buildTestWidget(prefs: prefs, navigatedRoutes: navigatedRoutes));
    await tester.pumpAndSettle();

    final skipBtn = find.text('Skip for now');
    await tester.ensureVisible(skipBtn);
    await tester.tap(skipBtn);
    await tester.pumpAndSettle();

    // Verify onboardingDone is true
    expect(prefs.getBool('onboarding_done'), isTrue);
    expect(navigatedRoutes, contains('/home'));
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
