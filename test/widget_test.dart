import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/router/app_router.dart';
import 'package:drive_rank/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await configureDependencies();
  });

  testWidgets('app boots and shows the brand wordmark on splash', (
    tester,
  ) async {
    await tester.pumpWidget(const DriveRankApp());
    await tester.pump();
    // flutter_animate schedules a zero-duration Timer in initState — pump
    // once more so it fires (and converts into Tickers that don't leak).
    await tester.pump(const Duration(milliseconds: 1));

    // Splash uppercases the wordmark for the animated entrance.
    expect(find.text(AppStrings.appName.toUpperCase()), findsOneWidget);

    // Tear down the splash so its route timer + flutter_animate's internal
    // tickers are cancelled before the framework's leak check runs.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('router is registered as a singleton', () {
    final a = getIt<AppRouter>();
    final b = getIt<AppRouter>();
    expect(identical(a, b), isTrue);
  });
}
