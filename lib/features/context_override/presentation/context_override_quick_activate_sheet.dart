import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/context_override_providers.dart';
import '../application/context_override_service.dart';
import '../domain/models/context_override.dart';
import '../application/override_attention_policy.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

/// Shows the quick-activate bottom sheet. 2 taps to activate:
///   1. Select override type.
///   2. Select duration preset → confirm.
Future<void> showContextOverrideQuickActivateSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          20,
          16,
          20,
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
        _handle(),
        Text(
          'Set attention mode',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tell the app what you\'re doing so it knows when to hold reminders.',
          style: TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        for (final type in _overrideTypes) ...[
          _OverrideTypeRow(
            type: type,
            onTap: () => setState(() => _selectedType = type),
          ),
          const SizedBox(height: 8),
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
        _handle(),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() {
                _selectedType = null;
                _selectedPreset = null;
                _showCustomSlider = false;
              }),
              child: const Icon(Icons.arrow_back_ios, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              '${type.icon}  ${type.displayName}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          OverrideAttentionPolicy.suppressionSummary(type),
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in presets)
              ChoiceChip(
                label: Text(preset.label),
                selected: _selectedPreset?.label == preset.label,
                onSelected: (_) => setState(() {
                  _selectedPreset = preset;
                  _showCustomSlider = preset.label == 'Custom';
                }),
              ),
          ],
        ),
        if (_showCustomSlider) ...[
          const SizedBox(height: 12),
          Text(
            'Custom: $_customMinutes min',
            style: const TextStyle(color: Colors.white70),
          ),
          Slider(
            value: _customMinutes.toDouble(),
            min: 15,
            max: 720,
            divisions: 47,
            label: '$_customMinutes min',
            onChanged: (v) => setState(() => _customMinutes = v.round()),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _canConfirm ? _confirm : null,
            child: const Text('Activate'),
          ),
        ),
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

  Widget _handle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Override type row ────────────────────────────────────────────────────────

class _OverrideTypeRow extends StatelessWidget {
  const _OverrideTypeRow({required this.type, required this.onTap});

  final ContextOverride type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    OverrideAttentionPolicy.suppressionSummary(type),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }
}
