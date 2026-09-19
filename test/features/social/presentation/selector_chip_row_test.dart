import 'package:drive_rank/core/constants/app_strings.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_scope.dart';
import 'package:drive_rank/features/social/presentation/widgets/selector_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The board grew a third selector in 4c, and three chips are the point
/// at which the row stops fitting on a small phone. What's pinned here
/// is that it degrades by scrolling rather than by reflowing into two
/// rows — which would undo the compaction the chips replaced two rows of
/// pills to achieve.
void main() {
  Future<void> pumpRow(WidgetTester tester, {required double width}) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SelectorChipRow(
            chips: [
              SelectorChip(
                icon: Icons.people_alt_rounded,
                label: AppStrings.rankingsScopeFriends,
                onTap: () {},
              ),
              SelectorChip(
                icon: Icons.flag_rounded,
                label: AppStrings.rankingsMetricLongestTrip,
                onTap: () {},
              ),
              SelectorChip(
                icon: Icons.calendar_today_rounded,
                label: AppStrings.rankingsPeriodAllTime,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('shows all three selectors on a roomy screen', (tester) async {
    await pumpRow(tester, width: 430);
    expect(find.byType(SelectorChip), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('on a narrow screen it scrolls instead of overflowing or '
      'wrapping into a second row', (tester) async {
    // Narrower than any shipping phone, so the row is definitely
    // over-full and the failure mode would be visible if it existed.
    await pumpRow(tester, width: 280);

    expect(tester.takeException(), isNull);
    expect(find.byType(SelectorChip), findsNWidgets(3));

    final scroller = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scroller.scrollDirection, Axis.horizontal);

    // Every chip stays on one line: the row's own height is the height
    // of a single chip, not two stacked.
    final rowHeight = tester.getSize(find.byType(SelectorChipRow)).height;
    final chipHeight = tester.getSize(find.byType(SelectorChip).first).height;
    expect(rowHeight, closeTo(chipHeight, 1));
  });

  testWidgets('the scope selector reads as the scope it is showing, so '
      'the chip and the rows can never disagree', (tester) async {
    await pumpRow(tester, width: 430);
    expect(
      find.text(LeaderboardScope.friends.label.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(LeaderboardScope.global.label.toUpperCase()),
      findsNothing,
    );
  });
}
