import 'dart:io';

import 'package:drive_rank/features/social/domain/entities/challenge.dart';
import 'package:drive_rank/features/social/domain/entities/competition_mirror.dart';
import 'package:drive_rank/features/social/domain/entities/leaderboard_period.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the client's field names against the deployed rules' whitelist.
///
/// The two are written in different languages, in different files, by
/// hand — `firestore.rules` lists the fields a public profile may carry,
/// and `CompetitionMirror`/`FirestoreCompetitionMirrorSink` decide what
/// actually gets written. If they disagree, every publish is rejected in
/// production while every Dart test and every emulator test still
/// passes: the emulator suite writes its own fixture document, not the
/// sink's real payload.
///
/// That is exactly the seam a live-device check would catch, and this
/// catches it without a network, a deploy, or a device.
void main() {
  test('every field the mirror publishes is allowed by firestore.rules, '
      'and the rules allow nothing the mirror never writes', () {
    final rules = File('firestore.rules').readAsStringSync();

    // The `hasOnly([...])` list inside the public_profiles match block.
    final block = RegExp(
      r'match /public_profiles/\{uid\}[\s\S]*?hasOnly\(\[([\s\S]*?)\]\)',
    ).firstMatch(rules);
    expect(
      block,
      isNotNull,
      reason: 'public_profiles rule or its field whitelist has moved',
    );

    final whitelisted = RegExp("'([A-Za-z_]+)'")
        .allMatches(block!.group(1)!)
        .map((m) => m.group(1)!)
        .toSet();

    expect(
      whitelisted,
      CompetitionMirror.allFields.toSet(),
      reason:
          'the rules whitelist and CompetitionMirror.allFields have drifted; '
          'a publish would be rejected in production',
    );
  });

  test('the field list covers every metric and period, so adding either '
      'one fails here rather than in production', () {
    for (final metric in CompetitionMetric.values) {
      for (final period in LeaderboardPeriod.values) {
        expect(
          CompetitionMirror.allFields,
          contains(CompetitionMirror.fieldFor(metric, period)),
          reason: '$metric/$period is not in the published field list',
        );
      }
    }
    // The identity half, named rather than counted — a bare number here
    // would silently absorb a field that was added by accident.
    const identity = [
      'username',
      'usernameLower',
      'carMake',
      'carModel',
      'countryCode',
      'inviteCode',
      'updatedAt',
    ];
    expect(
      CompetitionMirror.allFields,
      hasLength(
        identity.length +
            CompetitionMetric.values.length * LeaderboardPeriod.values.length,
      ),
    );
    expect(CompetitionMirror.allFields, containsAll(identity));
  });
}
