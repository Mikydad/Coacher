// Points economy client models (PT-1) — read-only mirrors of the
// server-owned ledger. The client can never write these (rules-denied);
// it earns by calling `grantPoints` and spends through stake callables.

class PointsTxn {
  const PointsTxn({
    required this.id,
    required this.source,
    required this.amount,
    required this.refId,
    required this.atMs,
  });

  final String id;

  /// `signup_bonus | earn_* | stake_* | spend_photo_removal`.
  final String source;

  /// Signed; forfeits are 0-amount audit rows (the burn happened at lock).
  final int amount;
  final String refId;
  final int atMs;

  factory PointsTxn.fromMap(Map<String, dynamic> m) => PointsTxn(
        id: (m['id'] as String?) ?? '',
        source: (m['source'] as String?) ?? '',
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        refId: (m['refId'] as String?) ?? '',
        atMs: (m['atMs'] as num?)?.toInt() ?? 0,
      );
}

/// D7 — one curated charity (admin-managed; clients only ever see active).
class Charity {
  const Charity({
    required this.id,
    required this.name,
    this.category,
  });

  final String id;
  final String name;
  final String? category;

  factory Charity.fromMap(Map<String, dynamic> m) => Charity(
        id: (m['id'] as String?) ?? '',
        name: (m['name'] as String?) ?? '',
        category: m['category'] as String?,
      );
}
