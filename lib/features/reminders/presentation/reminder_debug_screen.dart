import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../time_blocks/domain/models/scheduled_time_block.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';

/// Every notification the OS currently holds for us (FR-R-82).
///
/// Tester-mode gated. This is the tool every "why didn't it fire?" report
/// needs: it shows what is genuinely armed right now, versus what the app
/// believes, which is precisely the gap the T1 misfire lived in.
class ReminderDebugScreen extends ConsumerStatefulWidget {
  const ReminderDebugScreen({super.key});

  static const routeName = '/settings/reminder-debug';

  @override
  ConsumerState<ReminderDebugScreen> createState() =>
      _ReminderDebugScreenState();
}

class _ReminderDebugScreenState extends ConsumerState<ReminderDebugScreen> {
  late Future<_DebugSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DebugSnapshot> _load() async {
    final service = LocalNotificationsService.instance;
    final pending = await service.getPendingNotificationRequests();
    final active = await service.getActiveNotifications();
    final dayStart = DateTime.now().subtract(const Duration(days: 1));
    List<ScheduledTimeBlock> blocks = const [];
    try {
      blocks = await ref
          .read(timeBlockRepositoryProvider)
          .listBlocksForDateRange(
            dayStart,
            dayStart.add(const Duration(days: 3)),
          );
    } catch (_) {}
    return _DebugSnapshot(
      pending: pending
          .map(
            (p) => _DebugRow(
              id: p.id,
              title: p.title ?? '(no title)',
              body: p.body ?? '',
              payload: p.payload ?? '',
            ),
          )
          .toList(),
      delivered: active
          .map(
            (a) => _DebugRow(
              id: a.id ?? -1,
              title: a.title ?? '(no title)',
              body: a.body ?? '',
              payload: a.payload ?? '',
            ),
          )
          .toList(),
      blocks: blocks,
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('Armed reminders'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_DebugSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final snap = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SectionHeader(
                'Scheduled (${snap.pending.length})',
                subtitle: 'Waiting in the OS queue. iOS caps this at 64.',
              ),
              if (snap.pending.isEmpty) const _EmptyLine('Nothing armed.'),
              for (final row in snap.pending) _DebugTile(row: row),
              const SizedBox(height: 24),
              SectionHeader(
                'On screen (${snap.delivered.length})',
                subtitle: 'Already fired and still in the tray.',
              ),
              if (snap.delivered.isEmpty) const _EmptyLine('Tray is empty.'),
              for (final row in snap.delivered) _DebugTile(row: row),
              const SizedBox(height: 24),
              SectionHeader(
                'Time blocks (${snap.blocks.length})',
                subtitle:
                    'What overlap detection and the ladder boundary consult. '
                    'A timed task with a duration should have a row here.',
              ),
              if (snap.blocks.isEmpty)
                const _EmptyLine('No stored blocks — reminder-only tasks '
                    'and tasks without a duration create none.'),
              for (final block in snap.blocks) _BlockTile(block: block),
            ],
          );
        },
      ),
    );
  }
}

class _DebugSnapshot {
  const _DebugSnapshot({
    required this.pending,
    required this.delivered,
    required this.blocks,
  });
  final List<_DebugRow> pending;
  final List<_DebugRow> delivered;

  /// Stored [ScheduledTimeBlock]s — what the conflict gate and the ladder
  /// boundary actually consult. Added 2026-08-31 while chasing "overlap
  /// detection stopped firing": if a task you just saved with a duration has
  /// no row here, the conflict gate for the NEXT task has nothing to find,
  /// and the bug is on the write side, not in detection.
  final List<ScheduledTimeBlock> blocks;
}

class _DebugRow {
  const _DebugRow({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });
  final int id;
  final String title;
  final String body;
  final String payload;
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      text,
      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
    ),
  );
}

class _DebugTile extends StatelessWidget {
  const _DebugTile({required this.row});
  final _DebugRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (row.body.isNotEmpty)
            Text(
              row.body,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          const SizedBox(height: 2),
          // The payload carries the entity and slot — the two things a
          // "why didn't it fire" report actually needs.
          Text(
            'id ${row.id}${row.payload.isEmpty ? '' : ' · ${row.payload}'}',
            style: TextStyle(
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({required this.block});
  final ScheduledTimeBlock block;

  @override
  Widget build(BuildContext context) {
    String hhmm(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${block.entityKind} · ${hhmm(block.startAt)}–'
            '${hhmm(block.computedEndAt)} '
            '(${block.expectedDurationMinutes} min, '
            '${block.flexibilityType.name})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            block.entityId,
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
