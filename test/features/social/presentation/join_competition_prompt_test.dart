import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/core/database/app_database.dart';
import 'package:drive_rank/core/di/injection.dart';
import 'package:drive_rank/core/services/free_trip_counter_service.dart';
import 'package:drive_rank/core/services/locale_service.dart';
import 'package:drive_rank/features/social/data/services/competition_visibility.dart';
import 'package:drive_rank/features/social/presentation/pages/friends_page.dart';
import 'package:drive_rank/features/social/presentation/widgets/join_competition_prompt.dart';
import 'package:drive_rank/shared/repositories/user_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFreeTripCounterService extends Mock
    implements FreeTripCounterService {}

/// The settings row as a live value the test can move — the widgets
/// only ever watch it.
class _FakeSettings implements UserSettingsRepository {
  _FakeSettings(this.current);

  UserSettingsRow current;
  final _changes = StreamController<UserSettingsRow>.broadcast();

  void emit(UserSettingsRow row) {
    current = row;
    _changes.add(row);
  }

  @override
  Stream<UserSettingsRow> watch() async* {
    yield current;
    yield* _changes.stream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} is not watched');
}

/// Records the answer, and moves the row the way the real one does.
class _FakeVisibility implements CompetitionVisibility {
  _FakeVisibility(this.settings);

  final _FakeSettings settings;
  final List<String> answers = [];

  @override
  Future<void> join() async {
    answers.add('join');
    settings.emit(
      settings.current.copyWith(competitionOptIn: const Value(true)),
    );
  }

  @override
  Future<void> leave() async {
    answers.add('leave');
    settings.emit(
      settings.current.copyWith(competitionOptIn: const Value(false)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName}');
}

void main() {
  late UserSettingsRow fresh;
  late _FakeSettings settings;
  late _FakeVisibility visibility;

  // A real row, built once outside the widget tests' fake clock, so the
  // fakes carry every field the app would have.
  setUpAll(() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repo = UserSettingsRepository(
      db,
      LocaleService.forLocale(const Locale('en', 'US')),
      _MockFreeTripCounterService(),
    );
    fresh = await repo.read();
    await db.close();
  });

  setUp(() {
    settings = _FakeSettings(
      fresh.copyWith(
        username: 'basit',
        competitionOptIn: const Value(null),
      ),
    );
    visibility = _FakeVisibility(settings);
    getIt
      ..registerSingleton<UserSettingsRepository>(settings)
      ..registerSingleton<CompetitionVisibility>(visibility);
  });

  tearDown(getIt.reset);

  void onboarded() => settings.current = settings.current.copyWith(
    onboardingComplete: true,
  );

  Future<void> pumpShell(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CompetitionInvite(child: Text('shell'))),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the notice says exactly what becomes visible, and offers '
      'both answers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: JoinCompetitionDialog())),
    );
    expect(find.text(AppStrings.competitionJoinTitle), findsOneWidget);
    expect(find.text(AppStrings.competitionJoinBody), findsOneWidget);
    expect(find.text(AppStrings.competitionJoinAction), findsOneWidget);
    expect(find.text(AppStrings.competitionNotNow), findsOneWidget);
    expect(
      AppStrings.competitionJoinBody,
      allOf(
        contains('username'),
        contains('car'),
        contains('country'),
        contains('competition stats'),
        contains('Settings'),
      ),
    );
  });

  testWidgets('asked once after onboarding; "Not now" is recorded and the '
      'notice does not come back', (tester) async {
    onboarded();
    await pumpShell(tester);
    expect(find.text(AppStrings.competitionJoinTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.competitionNotNow));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.competitionJoinTitle), findsNothing);
    expect(visibility.answers, ['leave']);

    await pumpShell(tester);
    expect(find.text(AppStrings.competitionJoinTitle), findsNothing);
    expect(visibility.answers, ['leave']);
  });

  testWidgets('"Join Competition" joins', (tester) async {
    onboarded();
    await pumpShell(tester);
    await tester.tap(find.text(AppStrings.competitionJoinAction));
    await tester.pumpAndSettle();
    expect(visibility.answers, ['join']);
  });

  testWidgets('tapping outside does not dismiss it — it needs an answer',
      (tester) async {
    onboarded();
    await pumpShell(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.competitionJoinTitle), findsOneWidget);
    expect(visibility.answers, isEmpty);
  });

  testWidgets('not shown during onboarding, or to someone who has already '
      'answered', (tester) async {
    await pumpShell(tester);
    expect(find.text(AppStrings.competitionJoinTitle), findsNothing);

    settings.current = settings.current.copyWith(
      onboardingComplete: true,
      competitionOptIn: const Value(true),
    );
    await pumpShell(tester);
    expect(find.text(AppStrings.competitionJoinTitle), findsNothing);
  });

  testWidgets('not shown while the rankings kill switch is off — there is '
      'nothing to join', (tester) async {
    settings.current = settings.current.copyWith(
      onboardingComplete: true,
      rankingsEnabled: false,
    );
    await pumpShell(tester);
    expect(find.text(AppStrings.competitionJoinTitle), findsNothing);
  });

  testWidgets('Friends asks to join before offering a search that could '
      'never find you back', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FriendsPage()));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.friendsJoinFirstTitle), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt_1_rounded), findsNothing);
    // Joining from here is offered only after saying what it shows.
    expect(find.text(AppStrings.friendsJoinFirstBody), findsOneWidget);
    expect(find.text(AppStrings.competitionJoinAction), findsOneWidget);
  });
}
