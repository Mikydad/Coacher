import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_response_handler.dart';
import '../core/sync/sync_service.dart';

/// Set to `true` after the first successful [SyncService.syncFromRemote] seed (PRD §4.6).
const String kIsarSeededV1PrefsKey = 'isar_seeded_v1';

/// On first install / pre-migration, blocks on a one-time Firestore → Isar pull so the UI is not empty.
///
/// If the pull throws (e.g. offline), shows [child] anyway and retries in the background without setting the flag.
class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key, required this.child});

  final Widget child;

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  var _ready = false;

  void _markReadyAndFlushIntent() {
    if (!mounted) return;
    setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flushPendingNotificationNavigationIntent();
    });
  }

  Future<void> _retrySeedInBackground() async {
    try {
      await SyncService.instance.syncFromRemote(force: true);
      final p = await SharedPreferences.getInstance();
      await p.setBool(kIsarSeededV1PrefsKey, true);
    } catch (e2, st2) {
      debugPrint('FirstLaunchGate: background seed retry failed: $e2\n$st2');
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(kIsarSeededV1PrefsKey) == true) {
      _markReadyAndFlushIntent();
      return;
    }

    try {
      await SyncService.instance.syncFromRemote(force: true);
      await prefs.setBool(kIsarSeededV1PrefsKey, true);
    } catch (e, st) {
      debugPrint('FirstLaunchGate: initial seed failed (showing app anyway): $e\n$st');
      unawaited(_retrySeedInBackground());
    }

    _markReadyAndFlushIntent();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Default [Material] uses a light surface — reads as a "blank white screen"
      // with a tiny spinner. Match the app shell so launch reads as intentional loading.
      return Material(
        color: const Color(0xFF050806),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFB7FF00)),
              const SizedBox(height: 20),
              const Text(
                'Loading your plan…',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    return widget.child;
  }
}
