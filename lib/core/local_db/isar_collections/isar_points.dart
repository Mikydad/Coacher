import 'package:isar_community/isar.dart';

import '../../../features/accountability/domain/models/points.dart';

part 'isar_points.g.dart';

/// Read-only mirror of `points_ledger/{uid}/txns` (append-only, immutable;
/// hydrated by [RemoteIsarMerge] with an updatedAtMs cursor).
@collection
class IsarPointsTxn {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String txnId;

  @Index()
  late int updatedAtMs;

  late String source;
  late int amount;
  late String refId;
  late int atMs;

  static IsarPointsTxn fromDomain(PointsTxn t) {
    return IsarPointsTxn()
      ..txnId = t.id
      ..updatedAtMs = t.atMs
      ..source = t.source
      ..amount = t.amount
      ..refId = t.refId
      ..atMs = t.atMs;
  }

  PointsTxn toDomain() => PointsTxn(
        id: txnId,
        source: source,
        amount: amount,
        refId: refId,
        atMs: atMs,
      );
}

/// Singleton row mirroring the denormalized balance doc — offline balance
/// display (PT-1 "synced to Isar read-only").
@collection
class IsarPointsBalance {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uid;

  @Index()
  late int updatedAtMs;

  late int balance;
}

/// Mirror of the curated `charities` collection (active entries only, D7).
@collection
class IsarCharity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String charityId;

  @Index()
  late int updatedAtMs;

  late String name;
  String? category;

  static IsarCharity fromDomain(Charity c, int updatedAtMs) {
    return IsarCharity()
      ..charityId = c.id
      ..updatedAtMs = updatedAtMs
      ..name = c.name
      ..category = c.category;
  }

  Charity toDomain() => Charity(id: charityId, name: name, category: category);
}
