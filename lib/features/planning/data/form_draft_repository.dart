import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../application/form_draft_providers.dart';

/// Persists in-progress form JSON blobs locally.
///
/// Uses [SharedPreferences] (not Isar) to avoid schema churn for short-lived drafts.
class FormDraftRepository {
  static const _keyPrefix = 'form_draft_v1_';

  Future<void> save(String key, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$key', jsonEncode(json));
  }

  Future<Map<String, dynamic>?> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (e) {
      debugPrint('form_draft_repository: swallowed error: $e');
    }
    return null;
  }

  Future<void> delete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$key');
  }

  bool isExpired(int savedAtMs, {int ttlMinutes = kFormDraftTtlMinutes}) {
    final ageMs = DateTime.now().millisecondsSinceEpoch - savedAtMs;
    return ageMs > ttlMinutes * 60 * 1000;
  }
}
