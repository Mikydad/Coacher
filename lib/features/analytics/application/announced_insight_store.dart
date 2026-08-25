import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/date_keys.dart';

/// The coaching banner's frozen copy (2026-08-25).
///
/// A coaching-insight notification is dispatched minutes-to-hours before
/// the user taps it, and every insight recompute wholesale-replaces the
/// day's rows under date-keyed ids — so by tap time the advertised insight
/// often no longer resolves and Progress shrugged with the generic
/// fallback ("not available yet"). The fix: freeze the copy at dispatch,
/// device-local (notifications are device-local), one slot mirroring the
/// one OS coaching-banner slot, expiring at day rollover.
class AnnouncedInsight {
  const AnnouncedInsight({
    required this.insightId,
    required this.message,
    required this.caption,
    required this.dateKey,
  });

  final String insightId;

  /// The insight's full message as bannered.
  final String message;

  /// The detail caption at dispatch time; empty when none existed.
  final String caption;

  /// [DateKeys] day the banner was dispatched — the snapshot's lifetime.
  final String dateKey;

  Map<String, Object?> toMap() => {
    'insightId': insightId,
    'message': message,
    'caption': caption,
    'dateKey': dateKey,
  };

  static AnnouncedInsight? fromMap(Map<String, Object?> m) {
    final id = m['insightId'];
    final message = m['message'];
    if (id is! String || id.isEmpty || message is! String || message.isEmpty) {
      return null;
    }
    return AnnouncedInsight(
      insightId: id,
      message: message,
      caption: (m['caption'] as String?) ?? '',
      dateKey: (m['dateKey'] as String?) ?? '',
    );
  }
}

class AnnouncedInsightStore {
  static const prefsKey = 'coaching_announced_insight_v1';

  Future<void> save(AnnouncedInsight announced) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(announced.toMap()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }

  /// The snapshot, or null when none exists or it's from another day.
  Future<AnnouncedInsight?> readFor(String dateKey) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final announced = AnnouncedInsight.fromMap(
        decoded.cast<String, Object?>(),
      );
      if (announced == null || announced.dateKey != dateKey) return null;
      return announced;
    } catch (_) {
      return null;
    }
  }
}

final announcedInsightStoreProvider = Provider<AnnouncedInsightStore>(
  (ref) => AnnouncedInsightStore(),
);

/// Today's frozen banner copy for the Progress screen's fallback path.
final announcedInsightTodayProvider = FutureProvider<AnnouncedInsight?>(
  (ref) => ref
      .watch(announcedInsightStoreProvider)
      .readFor(DateKeys.todayKey(DateTime.now())),
);
