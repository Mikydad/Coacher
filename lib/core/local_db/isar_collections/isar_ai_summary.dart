import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../../../features/analytics/domain/models/ai_summary_response.dart';

part 'isar_ai_summary.g.dart';

@collection
class IsarAiSummary {
  Id id = Isar.autoIncrement;

  /// Matches [AiSummaryResponse.focusId] — links summary to its focus.
  @Index(unique: true)
  late String focusId;

  @Index()
  late String summaryType;

  /// True when this was produced by [DeterministicCoachingRenderer].
  @Index()
  late bool isFallback;

  @Index()
  late int generatedAtMs;

  late String promptVersion;
  late String payloadJson;
  late int schemaVersion;

  static IsarAiSummary fromDomain(AiSummaryResponse summary) {
    return IsarAiSummary()
      ..focusId = summary.focusId
      ..summaryType = summary.summaryType.name
      ..isFallback = summary.isFallback
      ..generatedAtMs = summary.generatedAtMs
      ..promptVersion = summary.promptVersion
      ..payloadJson = jsonEncode(summary.toMap())
      ..schemaVersion = summary.schemaVersion;
  }

  AiSummaryResponse toDomain() {
    final payload = _decodePayload(payloadJson);
    return AiSummaryResponse.fromMap(payload);
  }
}

Map<String, dynamic> _decodePayload(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (e) {
    debugPrint('isar_ai_summary: swallowed error: $e');
  }
  return const <String, dynamic>{};
}
