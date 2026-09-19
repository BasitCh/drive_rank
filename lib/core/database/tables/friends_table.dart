import 'package:drift/drift.dart';

/// An accepted friendship, one row per direction.
///
/// `remoteId` is the stable UUID this row will sync under once a
/// Firestore-backed implementation exists — mirrors `Trips.remoteId`.
/// `(ownerUid, friendUid)` is unique so the same pair can't be added twice.
@DataClassName('FriendRow')
class Friends extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text()();
  TextColumn get ownerUid => text()();
  TextColumn get friendUid => text()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {ownerUid, friendUid},
  ];
}
