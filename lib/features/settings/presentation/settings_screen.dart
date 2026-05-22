import 'package:flutter/material.dart';

import '../../coaching/presentation/coaching_style_settings_section.dart';
import '../../context_override/presentation/override_settings_section.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kSurface = Color(0xFF0E0E0E);
const _kSurfaceHigh = Color(0xFF201F1F);
const _kOnSurface = Color(0xFFFFFFFF);
const _kOnSurfaceVariant = Color(0xFFADAAAA);

/// Account Settings screen — Security, Privacy & Data.
///
/// Reuses the existing [CoachingStyleSettingsSection] and
/// [OverrideSettingsSection] components, now restyled to match the
/// Obsidian Pulse design language.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _kOnSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kOnSurface,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        children: [
          _SettingsSectionHeader(label: 'Coaching Style'),
          const SizedBox(height: 10),
          const _ObsidianCard(child: CoachingStyleSettingsSection()),
          const SizedBox(height: 32),
          _SettingsSectionHeader(label: 'Attention & Sleep Window'),
          const SizedBox(height: 10),
          const _ObsidianCard(child: OverrideSettingsSection()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: _kOnSurfaceVariant,
      ),
    );
  }
}

class _ObsidianCard extends StatelessWidget {
  const _ObsidianCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
