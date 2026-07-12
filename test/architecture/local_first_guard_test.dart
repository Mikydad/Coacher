import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture guard for the offline-first contract
/// (`OPTIMISTIC_UPDATES_AUDIT.md`, `CLAUDE.md`).
///
/// A Firestore `set()`/`delete()`/`update()` future completes only on
/// **server acknowledgment** — awaiting one on an interaction path blocks the
/// UI for a network round-trip (and indefinitely offline, because a dead
/// connection never throws). That exact pattern caused the app-wide save/load
/// lag fixed in July 2026. User-data writes must instead commit to Isar and
/// replicate through the outbox (`lib/core/sync/outbox_writer.dart`).
///
/// This test is a tripwire, not a proof: it bans the direct
/// `await FirebaseFirestore.instance … set/delete/update` shape outside an
/// explicit allowlist. If it fails on your new code, route the write through
/// `outboxUpsert`/`outboxDelete` — or, if the write is genuinely
/// network-inherent (multi-user state that needs server truth), add the file
/// to the allowlist WITH a reason, and handle failure honestly in the UI.
void main() {
  const allowlist = <String, String>{
    // The outbox flusher — the one place that is SUPPOSED to await server
    // acks, off the UI thread, with retry + stuck-writes surfacing.
    'lib/core/sync/sync_service.dart':
        'outbox flusher: background push with retry',
    // Multi-user circle membership: member counts / join limits need server
    // transactions and rules-checked truth. UI wraps these with explicit
    // loading + error feedback (optimistic-then-honest class).
    'lib/features/community/application/user_circle_membership_service.dart':
        'multi-user transactions require server truth',
  };

  test('no awaited Firestore writes outside the sync outbox', () {
    final banned = RegExp(
      r'await\s+FirebaseFirestore\s*\.\s*instance',
      multiLine: true,
    );
    final violations = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      final path = file.path.replaceAll(r'\', '/');
      if (allowlist.containsKey(path)) continue;
      final source = file.readAsStringSync();

      for (final match in banned.allMatches(source)) {
        final stmtEnd = source.indexOf(';', match.start);
        final statement = source.substring(
          match.start,
          stmtEnd == -1 ? source.length : stmtEnd,
        );
        final isWrite = statement.contains('.set(') ||
            statement.contains('.delete()') ||
            statement.contains('.update(');
        if (isWrite) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          violations.add('$path:$line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Awaited Firestore write(s) found outside the sync outbox:\n'
          '  ${violations.join('\n  ')}\n'
          'Route user-data writes through outboxUpsert/outboxDelete '
          '(lib/core/sync/outbox_writer.dart) so the UI never waits on the '
          'network. See CLAUDE.md → Hard architecture rules.',
    );
  });

  test('allowlisted files still exist (keep the allowlist honest)', () {
    for (final path in allowlist.keys) {
      expect(
        File(path).existsSync(),
        isTrue,
        reason: '$path is allowlisted but no longer exists — remove the entry.',
      );
    }
  });
}
