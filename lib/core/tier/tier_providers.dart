import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/application/auth_providers.dart';
import 'tier_gate.dart';
import 'tier_limits.dart';
import 'tier_limits_service.dart';

String _entitlementKeyForUid(String uid) => 'pro_entitlement_v1_$uid';

/// Current tier limits. Starts at [TierLimits.defaults] synchronously (so
/// gates always have a value, offline included) and upgrades to the fetched
/// Remote Config value when it lands.
final tierLimitsProvider =
    StateNotifierProvider<TierLimitsController, TierLimits>(
      (ref) => TierLimitsController(),
    );

class TierLimitsController extends StateNotifier<TierLimits> {
  /// [loadRemote] false = tests: state stays at the seeded value.
  TierLimitsController({bool loadRemote = true, TierLimits? seed})
    : super(seed ?? TierLimits.defaults) {
    if (loadRemote) _load();
  }

  Future<void> _load() async {
    final limits = await TierLimitsService.instance.limits();
    if (mounted) state = limits;
  }

  /// Re-fetch after a console push (debug/tester surface).
  Future<void> refresh() async {
    await TierLimitsService.instance.refresh();
    await _load();
  }
}

/// Whether the signed-in account has the Pro entitlement.
///
/// Placeholder source of truth: a per-uid local flag, mirroring
/// [TesterModeController]'s account isolation (never effective for
/// anonymous sessions, cannot leak across accounts). When RevenueCat ships
/// this controller's storage is replaced by the synced entitlement doc —
/// consumers of [userTierProvider] don't change.
final proEntitlementProvider =
    StateNotifierProvider<ProEntitlementController, bool>(
      (ref) => ProEntitlementController(ref),
    );

class ProEntitlementController extends StateNotifier<bool> {
  ProEntitlementController([this._ref]) : super(false) {
    _init();
  }

  final Ref? _ref;

  String? _uid;
  bool _registered = false;

  void _init() {
    final ref = _ref;
    if (ref == null) return;
    ref.listen<String?>(authUidProvider, (_, uid) {
      _recompute(uid, ref.read(isRegisteredProvider));
    }, fireImmediately: true);
    ref.listen<bool>(isRegisteredProvider, (_, registered) {
      _recompute(ref.read(authUidProvider), registered);
    }, fireImmediately: true);
  }

  Future<void> _recompute(String? uid, bool registered) async {
    _uid = uid;
    _registered = registered;
    if (uid == null || !registered) {
      if (mounted) state = false;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final entitled = prefs.getBool(_entitlementKeyForUid(uid)) ?? false;
    if (mounted) state = entitled;
  }

  /// Sets the entitlement for the signed-in registered account. Debug and
  /// (later) purchase-flow surface; ignored for anonymous sessions.
  Future<bool> setEntitled(bool entitled) async {
    final uid = _uid;
    if (uid == null || !_registered) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_entitlementKeyForUid(uid), entitled);
    if (mounted) state = entitled;
    return true;
  }
}

final userTierProvider = Provider<UserTier>(
  (ref) =>
      ref.watch(proEntitlementProvider) ? UserTier.pro : UserTier.free,
);

/// The ready-to-use gate: current limits × current tier.
final tierGateProvider = Provider<TierGate>(
  (ref) => TierGate(
    limits: ref.watch(tierLimitsProvider),
    tier: ref.watch(userTierProvider),
  ),
);
