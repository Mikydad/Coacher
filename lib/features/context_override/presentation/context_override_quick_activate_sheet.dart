import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/context_override_providers.dart';
import '../application/context_override_service.dart';
import '../application/override_attention_policy.dart';
import '../domain/models/context_override.dart';
import 'widgets/attention_mode_widgets.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

/// Shows the quick-activate bottom sheet. 2 taps to activate:
///   1. Select override type.
///   2. Select duration preset → confirm.
Future<void> showContextOverrideQuickActivateSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AttentionModeColors.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => const _QuickActivateSheet(),
  );
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _QuickActivateSheet extends ConsumerStatefulWidget {
  const _QuickActivateSheet();

  @override
  ConsumerState<_QuickActivateSheet> createState() =>
      _QuickActivateSheetState();
}

class _QuickActivateSheetState extends ConsumerState<_QuickActivateSheet> {
  ContextOverride? _selectedType;
  OverridePreset? _selectedPreset;

  // For focus custom duration (minutes, 15–720).
  int _customMinutes = 60;
  bool _showCustomSlider = false;

  static const _overrideTypes = [
    ContextOverride.meeting,
    ContextOverride.focus,
    ContextOverride.sleep,
    ContextOverride.vacation,
    ContextOverride.doNotDisturb,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: _selectedType == null ? _typePickerStep() : _durationStep(),
        ),
      ),
    );
  }

  // ─── Step 1: Type picker ───────────────────────────────────────────────────

  Widget _typePickerStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AttentionModeSheetHandle(),
        const AttentionModeSheetHeader(
          subtitle:
              'Tell the app what you\'re doing so it knows when to hold reminders.',
        ),
        const SizedBox(height: 20),
        for (final type in _overrideTypes) ...[
          AttentionModeTypeCard(
            icon: type.icon,
            title: type.displayName,
            subtitle: OverrideAttentionPolicy.suppressionSummary(type),
            onTap: () => setState(() => _selectedType = type),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ─── Step 2: Duration selector ────────────────────────────────────────────

  Widget _durationStep() {
    final type = _selectedType!;
    final presets = presetDurations(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AttentionModeSheetHandle(),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _selectedType = null;
                _selectedPreset = null;
                _showCustomSlider = false;
              }),
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
            ),
            Text(type.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                type.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          OverrideAttentionPolicy.suppressionSummary(type),
          style: const TextStyle(
            color: AttentionModeColors.label,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in presets)
              AttentionModeDurationChip(
                label: preset.label,
                selected: _selectedPreset?.label == preset.label,
                onSelected: () => setState(() {
                  _selectedPreset = preset;
                  _showCustomSlider = preset.label == 'Custom';
                }),
              ),
          ],
        ),
        if (_showCustomSlider) ...[
          const SizedBox(height: 16),
          Text(
            'Custom: $_customMinutes min',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AttentionModeColors.lime,
              inactiveTrackColor: AttentionModeColors.card,
              thumbColor: AttentionModeColors.lime,
              overlayColor: AttentionModeColors.lime.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _customMinutes.toDouble(),
              min: 15,
              max: 720,
              divisions: 47,
              label: '$_customMinutes min',
              onChanged: (v) => setState(() => _customMinutes = v.round()),
            ),
          ),
        ],
        const SizedBox(height: 24),
        AttentionModeActivateButton(enabled: _canConfirm, onPressed: _confirm),
      ],
    );
  }

  bool get _canConfirm {
    if (_selectedPreset == null) return false;
    if (_showCustomSlider && _customMinutes < 15) return false;
    return true;
  }

  Future<void> _confirm() async {
    final type = _selectedType!;
    final preset = _selectedPreset!;

    DateTime? expiresAt;
    if (preset.label == 'Custom') {
      expiresAt = DateTime.now().add(Duration(minutes: _customMinutes));
    } else if (preset.duration != null) {
      expiresAt = DateTime.now().add(preset.duration!);
    }
    // null expiresAt = "Until I end it"

    await ref
        .read(contextOverrideServiceProvider)
        .activateOverride(type: type, expiresAt: expiresAt);

    if (mounted) Navigator.pop(context);
  }
}
