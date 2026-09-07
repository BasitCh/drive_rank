import 'package:flutter/foundation.dart';

/// What kind of thing is on the other side of a head-to-head.
enum OpponentKind { benchmark, person }

/// The other side of a comparison.
///
/// One type for both kinds so the compare sheet has a single shape to
/// render, and one place where the rule lives: **a benchmark has no
/// identity.** No flag, no car, no photo — it is a published constant,
/// and inventing any of those would dress a number up as a person.
/// A person carries theirs, plus when they published it, because their
/// figure is a snapshot rather than a constant.
@immutable
class Opponent {
  const Opponent.benchmark({required this.id, required this.displayName})
    : kind = OpponentKind.benchmark,
      countryCode = '',
      carMake = '',
      carModel = '',
      publishedAt = null,
      isStale = false;

  const Opponent.person({
    required this.id,
    required this.displayName,
    this.countryCode = '',
    this.carMake = '',
    this.carModel = '',
    this.publishedAt,
    this.isStale = false,
  }) : kind = OpponentKind.person;

  /// A benchmark's catalogue id, or a person's uid.
  final String id;
  final String displayName;
  final OpponentKind kind;

  final String countryCode;
  final String carMake;
  final String carModel;

  /// When a person's figures were published. Null for a benchmark, whose
  /// values are the same on every device on every day.
  final DateTime? publishedAt;

  /// Whether [publishedAt] is old enough that the sheet should say so.
  final bool isStale;

  bool get isBenchmark => kind == OpponentKind.benchmark;
}
