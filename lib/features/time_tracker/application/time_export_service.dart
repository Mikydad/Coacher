import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/activity_event_repository.dart';
import '../domain/time_export.dart';
import 'time_tracker_providers.dart';

/// A rendered export, ready to hand to the share sheet.
class TimeExportFile {
  const TimeExportFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
    required this.text,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  /// The same content as [bytes], for tests and previews.
  final String text;
}

/// Builds the export from Isar only — one local read, no network, so it
/// works identically in airplane mode. The failure story is the share
/// sheet being dismissed, which is not a failure.
class TimeExportService {
  TimeExportService({
    required ActivityEventRepository repository,
    required Map<String, String> Function() categoryOf,
    DateTime Function()? now,
  }) : _repository = repository,
       _categoryOf = categoryOf,
       _now = now ?? DateTime.now;

  final ActivityEventRepository _repository;
  final Map<String, String> Function() _categoryOf;
  final DateTime Function() _now;

  Future<TimeExport> build(TimeExportPeriod period) async {
    final events = await _repository.fetchRangeOnce(
      period.startMs,
      period.fetchEndMs,
    );
    return buildTimeExport(
      period,
      events,
      exportedAt: _now(),
      categoryOf: _categoryOf(),
    );
  }

  Future<TimeExportFile> render(
    TimeExportPeriod period,
    TimeExportFormat format,
  ) async {
    final export = await build(period);
    final text = renderTimeExport(export, format);
    return TimeExportFile(
      name: '${period.fileStem}.${format.extension}',
      mimeType: format.mimeType,
      bytes: Uint8List.fromList(utf8.encode(text)),
      text: text,
    );
  }
}

final timeExportServiceProvider = Provider<TimeExportService>(
  (ref) => TimeExportService(
    repository: ref.read(activityEventRepositoryProvider),
    categoryOf: () => ref.read(activityCategoryMapProvider),
  ),
);

/// Hands a file to the OS share sheet. Overridable so widget tests can
/// capture what would have been shared instead of hitting the platform.
typedef ShareTimeExport = Future<void> Function(TimeExportFile file);

final shareTimeExportProvider = Provider<ShareTimeExport>(
  (ref) => (file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(file.bytes, mimeType: file.mimeType, name: file.name),
        ],
        subject: 'SidePal — ${file.name}',
      ),
    );
  },
);
