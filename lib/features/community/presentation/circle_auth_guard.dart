import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/tier/upgrade_prompt.dart';

/// Gates account-only circle actions (creating or joining a circle).
///
/// Browsing circles and opening circle details stay open to guests; only
/// identity-bound actions call this. Returns `true` when the user has an
/// account and the action may proceed. Guests get the shared account sheet
/// ([ensureAccountFor], decision 2026-09-27) — sign in keeps their data —
/// and the action continues only if the link succeeded. [ref] and
/// [actionLabel] are kept for the existing call sites; the sheet names the
/// feature ("groups") rather than the action.
Future<bool> ensureRegisteredForCircleAction(
  BuildContext context,
  WidgetRef ref, {
  required String actionLabel,
}) {
  return ensureAccountFor(context, feature: 'groups');
}
