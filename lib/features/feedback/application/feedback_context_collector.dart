import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../app/application/main_tab_navigation.dart';
import '../../../core/firebase/firestore_paths.dart';
import '../../../core/presentation/theme_brightness_controller.dart';
import '../../../core/sync/sync_service.dart';
import 'feedback_route_tracker.dart';

/// App version/build, loaded once (also feeds the Profile version footer).
final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

final feedbackContextCollectorProvider = Provider<FeedbackContextCollector>(
  (ref) => FeedbackContextCollector(ref),
);

/// Native channel returning {model, osVersion} — implemented in
/// AppDelegate.swift / MainActivity.kt. In-house instead of device_info_plus,
/// whose iOS code doesn't compile against this Xcode SDK.
const _deviceInfoChannel = MethodChannel('pathpal/device_info');

Future<Map<String, String>> _loadDeviceInfo() async {
  final raw = await _deviceInfoChannel.invokeMapMethod<String, String>(
    'getDeviceInfo',
  );
  return raw ?? const {};
}

/// Assembles the diagnostic snapshot attached to every feedback report.
///
/// Feedback must never fail because a plugin does: every lookup is fenced
/// and falls back to 'unknown'.
class FeedbackContextCollector {
  FeedbackContextCollector(
    this._ref, {
    Future<PackageInfo> Function()? packageInfoLoader,
    Future<Map<String, String>> Function()? deviceInfoLoader,
    Future<List<ConnectivityResult>> Function()? connectivityLoader,
  }) : _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform,
       _deviceInfoLoader = deviceInfoLoader ?? _loadDeviceInfo,
       _connectivityLoader =
           connectivityLoader ?? (() => Connectivity().checkConnectivity());

  final Ref _ref;
  final Future<PackageInfo> Function() _packageInfoLoader;
  final Future<Map<String, String>> Function() _deviceInfoLoader;
  final Future<List<ConnectivityResult>> Function() _connectivityLoader;

  // Plugin answers never change mid-session — cache after first success.
  PackageInfo? _pkg;
  String? _deviceModel;
  String? _osVersion;

  static const _tabNames = [
    'home',
    'coach',
    'goals',
    'progress',
    'community',
    'profile',
  ];

  Future<Map<String, String>> collect() async {
    final out = <String, String>{};

    await _guardAsync(() async {
      _pkg ??= await _packageInfoLoader();
      out['appVersion'] = _pkg!.version;
      out['buildNumber'] = _pkg!.buildNumber;
    }, () => out['appVersion'] = 'unknown');

    _guard(() {
      out['platform'] = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
          ? 'android'
          : Platform.operatingSystem;
    }, () => out['platform'] = 'unknown');

    await _guardAsync(() async {
      if (_deviceModel == null) {
        final info = await _deviceInfoLoader();
        _deviceModel = info['model'];
        _osVersion = info['osVersion'];
      }
      out['deviceModel'] = _deviceModel ?? 'unknown';
      out['osVersion'] = _osVersion ?? 'unknown';
    }, () {
      out['deviceModel'] = 'unknown';
      out['osVersion'] = 'unknown';
    });

    _guard(
      () => out['uid'] = FirestorePaths.activeUid,
      () => out['uid'] = 'unknown',
    );

    _guard(() {
      final index = _ref.read(mainTabIndexProvider);
      out['tab'] = index >= 0 && index < _tabNames.length
          ? _tabNames[index]
          : '$index';
    }, () => out['tab'] = 'unknown');

    _guard(
      () => out['topRoute'] = FeedbackRouteTracker.topRouteName.value ?? '/',
      () => out['topRoute'] = 'unknown',
    );

    _guard(
      () => out['brightness'] = _ref.read(themeBrightnessProvider).name,
      () => out['brightness'] = 'unknown',
    );

    await _guardAsync(() async {
      final results = await _connectivityLoader();
      out['connectivity'] = results.map((r) => r.name).join(',');
    }, () => out['connectivity'] = 'unknown');

    _guard(
      () => out['syncPending'] = '${SyncService.instance.pendingCount.value}',
      () => out['syncPending'] = 'unknown',
    );

    out['timestampLocalIso'] = DateTime.now().toIso8601String();
    return out;
  }

  void _guard(void Function() body, void Function() onError) {
    try {
      body();
    } catch (_) {
      onError();
    }
  }

  Future<void> _guardAsync(
    Future<void> Function() body,
    void Function() onError,
  ) async {
    try {
      await body();
    } catch (_) {
      onError();
    }
  }
}
