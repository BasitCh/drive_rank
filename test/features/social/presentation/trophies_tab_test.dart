import 'package:drive_rank/features/social/domain/entities/trophy.dart';
import 'package:drive_rank/features/social/presentation/widgets/trophies_tab.dart';
import 'package:drive_rank/features/social/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {List<Trophy> earned = const []}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrophiesTab(
            trophies: earned,
            formatUnlockedAt: (d) => '${d.day}/${d.month}',
          ),
        ),
      ),
    );
  }

  testWidgets('shows the whole set, so there is something to aim at',
      (tester) async {
    await pump(tester);
    expect(find.byType(TrophyTile), findsNWidgets(TrophyType.values.length));
  });

  testWidgets('every tile is actually laid out — the grid rendered blank on '
      'device because the rows stretched into an unbounded height',
      (tester) async {
    await pump(tester);
    for (final tile in tester.widgetList<TrophyTile>(find.byType(TrophyTile))) {
      final size = tester.getSize(find.byWidget(tile));
      expect(size.height, greaterThan(0), reason: '${tile.type.name} collapsed');
      expect(size.width, greaterThan(0), reason: '${tile.type.name} collapsed');
    }
    expect(find.text(TrophyType.firstTarget.title), findsOneWidget);
    expect(find.text(TrophyType.rivalHunter.title), findsOneWidget);
  });

  testWidgets('earned trophies come first and carry their unlock date',
      (tester) async {
    await pump(
      tester,
      earned: [
        Trophy(
          id: 'consistent:u:1',
          uid: 'u',
          type: TrophyType.consistent,
          unlockedAt: DateTime(2026, 9, 3),
        ),
      ],
    );

    final first = tester.widgetList<TrophyTile>(find.byType(TrophyTile)).first;
    expect(first.type, TrophyType.consistent);
    expect(find.text('3/9'), findsOneWidget);
  });

  testWidgets('paired rows share a height, so the grid does not look ragged',
      (tester) async {
    await pump(tester);
    final tiles = find.byType(TrophyTile);
    expect(
      tester.getSize(tiles.at(0)).height,
      tester.getSize(tiles.at(1)).height,
    );
  });
}
