import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/firebase/firestore_paths.dart';
import 'package:sidepal/core/storage/app_storage_dir.dart';
import 'package:sidepal/features/analytics/application/announced_insight_store.dart';
import 'package:sidepal/features/execution/data/timer_runtime_cache.dart';
import 'package:sidepal/features/execution/domain/models/timer_session.dart';
import 'package:sidepal/features/execution/domain/task_timer_engine.dart';
import 'package:sidepal/features/focus/data/focus_resume_store.dart';
import 'package:sidepal/features/reminders/application/strategist_proposals_store.dart';
import 'package:sidepal/features/thinking/application/reflection_parser.dart';

/// Pre-launch audit H4: the per-account caches that live outside Isar are
/// owner-tagged, so another account's copy (left behind by a crash, or by
/// a logout that never reached the wipe) reads as nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimerRuntimeCache', () {
    const cache = TimerRuntimeCache();

    tearDown(() => cache.clear());

    test('own save round-trips and carries the owner tag', () async {
      await cache.save(
        targetType: TimerSessionTargetType.task,
        taskId: 't1',
        blockId: 'b1',
        label: 'Deep work',
        phase: ExecutionPhase.inProgress,
        elapsed: const Duration(minutes: 3),
      );
      final data = await cache.load();
      expect(data?['taskId'], 't1');
      expect(data?['ownerUid'], FirestorePaths.activeUid);
    });

    test("another account's file is dropped AND deleted on load", () async {
      final dir = await getAppStorageDirectory();
      final file = File('${dir.path}/timer_runtime.json');
      await file.writeAsString(
        jsonEncode({
          'ownerUid': 'someone-else',
          'targetType': 'task',
          'taskId': 'their-task',
          'blockId': 'b',
          'label': 'Their private label',
          'phase': 'inProgress',
          'elapsedMs': 1000,
        }),
      );
      expect(await cache.load(), isNull);
      expect(await file.exists(), isFalse);
    });

    test('a legacy untagged file still loads (upgrade path)', () async {
      final dir = await getAppStorageDirectory();
      final file = File('${dir.path}/timer_runtime.json');
      await file.writeAsString(
        jsonEncode({'targetType': 'task', 'taskId': 'old', 'phase': 'paused'}),
      );
      expect((await cache.load())?['taskId'], 'old');
    });
  });

  group('FocusResumeStore', () {
    const store = FocusResumeStore();

    tearDown(FocusResumeStore.deleteFile);

    test('own elapsed round-trips', () async {
      await store.saveElapsed('t1', const Duration(minutes: 7));
      expect(await store.readElapsed('t1'), const Duration(minutes: 7));
    });

    test("another account's file reads as nothing", () async {
      await store.saveElapsed('t1', const Duration(minutes: 7));
      final dir = await getAppStorageDirectory();
      final file = File('${dir.path}/focus_resume.json');
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      json['_ownerUid'] = 'someone-else';
      await file.writeAsString(jsonEncode(json));
      expect(await store.readElapsed('t1'), isNull);
    });

    test('deleteFile removes the file', () async {
      await store.saveElapsed('t1', const Duration(minutes: 1));
      await FocusResumeStore.deleteFile();
      final dir = await getAppStorageDirectory();
      expect(await File('${dir.path}/focus_resume.json').exists(), isFalse);
    });
  });

  group('StrategistProposalsStore', () {
    test("another account's proposals read as empty", () async {
      final store = StrategistProposalsStore();
      await store.saveForDay('2026-09-15', const [
        ReminderStrategyProposal(
          kind: 'reschedule',
          taskId: 't1',
          taskTitle: 'Their task',
          suggestion: 'Their suggestion',
        ),
      ]);
      expect(await store.loadForDay('2026-09-15'), hasLength(1));

      final prefs = await SharedPreferences.getInstance();
      final raw = jsonDecode(prefs.getString(StrategistProposalsStore.prefsKey)!)
          as Map<String, dynamic>;
      raw['owner'] = 'someone-else';
      await prefs.setString(StrategistProposalsStore.prefsKey, jsonEncode(raw));
      expect(await store.loadForDay('2026-09-15'), isEmpty);
    });
  });

  group('AnnouncedInsightStore', () {
    test("another account's snapshot reads as null and is removed", () async {
      final store = AnnouncedInsightStore();
      const insight = AnnouncedInsight(
        insightId: 'i1',
        message: 'Personal coaching copy',
        caption: '',
        dateKey: '2026-09-15',
      );
      await store.save(insight);
      expect((await store.readFor('2026-09-15'))?.message, insight.message);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AnnouncedInsightStore.prefsKey,
        jsonEncode({...insight.toMap(), 'ownerUid': 'someone-else'}),
      );
      expect(await store.readFor('2026-09-15'), isNull);
      expect(prefs.getString(AnnouncedInsightStore.prefsKey), isNull);
    });
  });
}
