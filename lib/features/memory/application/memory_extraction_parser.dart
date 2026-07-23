import 'dart:convert';

import '../domain/models/memory_fact.dart';

/// A fact candidate parsed from the extract_memory response, with
/// provenance RESOLVED by quote verification: a claimed quote must
/// string-match the transcript or the fact is demoted to aiInferred
/// (settled: Q2 — the verification is what lets userStated assert).
class ExtractedFactCandidate {
  const ExtractedFactCandidate({
    required this.kind,
    required this.content,
    required this.provenance,
    this.sourceQuote,
    this.personName,
    this.structuredJson,
    this.confidence = 0.7,
  });

  final MemoryFactKind kind;
  final String content;
  final MemoryProvenance provenance;
  final String? sourceQuote;
  final String? personName;
  final String? structuredJson;
  final double confidence;
}

class ExtractedPersonCandidate {
  const ExtractedPersonCandidate({
    required this.name,
    required this.provenance,
    this.relationship,
    this.aliases = const [],
    this.sourceQuote,
  });

  final String name;
  final MemoryProvenance provenance;
  final String? relationship;
  final List<String> aliases;
  final String? sourceQuote;
}

/// A dormant observation — becomes an `IntentionStatus.dormant` intention
/// ("standing understanding": zero notifications until engaged).
class ExtractedObservationCandidate {
  const ExtractedObservationCandidate({
    required this.title,
    this.estimatedMinutes = 20,
  });

  final String title;
  final int estimatedMinutes;
}

class ParsedExtraction {
  const ParsedExtraction({
    this.facts = const [],
    this.people = const [],
    this.observations = const [],
    this.summary,
  });

  final List<ExtractedFactCandidate> facts;
  final List<ExtractedPersonCandidate> people;
  final List<ExtractedObservationCandidate> observations;
  final String? summary;

  bool get isEmpty =>
      facts.isEmpty && people.isEmpty && observations.isEmpty && summary == null;
}

/// Pure parsing + quote verification for extract_memory responses.
/// No I/O — unit-testable, and a malformed AI response can never throw
/// past this boundary (it degrades to an empty extraction).
class MemoryExtractionParser {
  const MemoryExtractionParser._();

  static const int maxFacts = 8;
  static const int maxPeople = 5;
  static const int maxObservations = 3;

  /// Normalizes for quote matching: lowercase, collapsed whitespace,
  /// straight quotes. Verbatim in spirit — resilient to whitespace and
  /// smart-quote drift, nothing else.
  static String normalizeForMatch(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
      .replaceAll(RegExp(r'[\u201C\u201D]'), '"')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// True when [quote] appears verbatim (normalized) in [transcript].
  static bool quoteMatches(String quote, String transcript) {
    final q = normalizeForMatch(quote);
    if (q.length < 3) return false;
    return normalizeForMatch(transcript).contains(q);
  }

  static ParsedExtraction parse(String content, String transcript) {
    Map<String, dynamic> decoded;
    try {
      final raw = jsonDecode(content);
      if (raw is! Map<String, dynamic>) return const ParsedExtraction();
      decoded = raw;
    } catch (_) {
      return const ParsedExtraction();
    }

    final facts = <ExtractedFactCandidate>[];
    final rawFacts = decoded['facts'];
    if (rawFacts is List) {
      for (final entry in rawFacts.take(maxFacts)) {
        if (entry is! Map) continue;
        final fact = _parseFact(Map<String, dynamic>.from(entry), transcript);
        if (fact != null) facts.add(fact);
      }
    }

    final people = <ExtractedPersonCandidate>[];
    final rawPeople = decoded['people'];
    if (rawPeople is List) {
      for (final entry in rawPeople.take(maxPeople)) {
        if (entry is! Map) continue;
        final person = _parsePerson(
          Map<String, dynamic>.from(entry),
          transcript,
        );
        if (person != null) people.add(person);
      }
    }

    final observations = <ExtractedObservationCandidate>[];
    final rawObservations = decoded['observations'];
    if (rawObservations is List) {
      for (final entry in rawObservations.take(maxObservations)) {
        if (entry is! Map) continue;
        final title = entry['title'];
        if (title is! String || title.trim().isEmpty) continue;
        final minutes = entry['estimatedMinutes'];
        observations.add(
          ExtractedObservationCandidate(
            title: title.trim(),
            estimatedMinutes: minutes is num
                ? minutes.toInt().clamp(5, 240)
                : 20,
          ),
        );
      }
    }

    final rawSummary = decoded['summary'];
    final summary = rawSummary is String && rawSummary.trim().isNotEmpty
        ? rawSummary.trim()
        : null;

    return ParsedExtraction(
      facts: facts,
      people: people,
      observations: observations,
      summary: summary,
    );
  }

  static ExtractedFactCandidate? _parseFact(
    Map<String, dynamic> entry,
    String transcript,
  ) {
    final content = entry['content'];
    if (content is! String || content.trim().isEmpty) return null;
    final trimmed = content.trim();
    final capped = trimmed.length > 200 ? trimmed.substring(0, 200) : trimmed;

    var kind = MemoryFactKind.semanticFact;
    final rawKind = entry['kind'];
    if (rawKind is String) {
      // episodicSummary is reserved for the summary channel; the model
      // cannot smuggle one in as a fact.
      final parsedKind = memoryFactKindFromStorage(rawKind);
      if (parsedKind != MemoryFactKind.episodicSummary) kind = parsedKind;
    }

    // THE quote-verification gate.
    final quote = entry['quote'];
    final verified =
        quote is String &&
        quote.trim().isNotEmpty &&
        quoteMatches(quote, transcript);

    final confidence = entry['confidence'];
    final structured = entry['structured'];

    return ExtractedFactCandidate(
      kind: kind,
      content: capped,
      provenance: verified
          ? MemoryProvenance.userStated
          : MemoryProvenance.aiInferred,
      sourceQuote: verified ? quote.trim() : null,
      personName: entry['personName'] is String &&
              (entry['personName'] as String).trim().isNotEmpty
          ? (entry['personName'] as String).trim()
          : null,
      structuredJson: structured is Map ? jsonEncode(structured) : null,
      confidence: confidence is num
          ? confidence.toDouble().clamp(0.0, 1.0)
          : (verified ? 0.95 : 0.6),
    );
  }

  static ExtractedPersonCandidate? _parsePerson(
    Map<String, dynamic> entry,
    String transcript,
  ) {
    final name = entry['name'];
    if (name is! String || name.trim().isEmpty) return null;
    final capped = name.trim().length > 80
        ? name.trim().substring(0, 80)
        : name.trim();

    final quote = entry['quote'];
    final verified =
        quote is String &&
        quote.trim().isNotEmpty &&
        quoteMatches(quote, transcript);

    final aliases = <String>[];
    final rawAliases = entry['aliases'];
    if (rawAliases is List) {
      for (final a in rawAliases.take(5)) {
        if (a is String && a.trim().isNotEmpty) aliases.add(a.trim());
      }
    }

    return ExtractedPersonCandidate(
      name: capped,
      relationship: entry['relationship'] is String &&
              (entry['relationship'] as String).trim().isNotEmpty
          ? (entry['relationship'] as String).trim()
          : null,
      aliases: aliases,
      provenance: verified
          ? MemoryProvenance.userStated
          : MemoryProvenance.aiInferred,
      sourceQuote: verified ? quote.trim() : null,
    );
  }
}
