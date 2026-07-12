import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/coaching/domain/models/enforcement_mode.dart';
import '../../../core/presentation/page_headers.dart';
import '../application/profile_providers.dart';

/// Full-screen picker for the user's default [EnforcementMode].
///
/// Navigated to from the Profile screen's "Enforcement Mode" tile.
class DefaultEnforcementModeSelectionScreen extends ConsumerStatefulWidget {
  const DefaultEnforcementModeSelectionScreen({super.key});

  static const routeName = '/profile/default-enforcement-mode';

  @override
  ConsumerState<DefaultEnforcementModeSelectionScreen> createState() =>
      _DefaultEnforcementModeSelectionScreenState();
}

class _DefaultEnforcementModeSelectionScreenState
    extends ConsumerState<DefaultEnforcementModeSelectionScreen> {
  EnforcementMode? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(defaultEnforcementModeProvider);
  }

  Future<void> _save() async {
    final mode = _selected;
    if (mode == null || _saving) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(profilePreferenceServiceProvider);
      await service.setDefaultEnforcementMode(mode);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('Enforcement Mode'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'How strictly should the app enforce your commitments '
                'on new tasks and habits by default?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: EnforcementMode.values
                    .map(
                      (mode) => _ModeTile(
                        mode: mode,
                        selected: _selected == mode,
                        onTap: () => setState(() => _selected = mode),
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: _selected == null || _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final EnforcementMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? cs.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: selected ? cs.onPrimaryContainer : cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? cs.onPrimaryContainer.withValues(alpha: 0.8)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
