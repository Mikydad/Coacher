import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../application/onboarding_flow_controller.dart';
import '../onboarding_ui.dart';

/// Screen 8 — Remember Day One. Photo is optional; the file stays on this
/// device (copied into app documents) — no upload in v1. It resurfaces on
/// the Screen 14 celebration.
class DayOneStep extends ConsumerStatefulWidget {
  const DayOneStep({super.key, required this.onSkip});

  final VoidCallback onSkip;

  @override
  ConsumerState<DayOneStep> createState() => _DayOneStepState();
}

class _DayOneStepState extends ConsumerState<DayOneStep> {
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        imageQuality: 88,
      );
      if (picked == null) return;
      // Picker files land in a temp dir the OS may purge — keep our copy.
      final docs = await getApplicationDocumentsDirectory();
      final ext = picked.path.split('.').last;
      final dest =
          '${docs.path}/day_one_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(picked.path).copy(dest);
      if (!mounted) return;
      ref.read(onboardingFlowControllerProvider.notifier).setDayOnePhoto(dest);
    } catch (e, st) {
      debugPrint('DayOneStep: photo pick failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t add that photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);
    final path = flow.dayOnePhotoPath;
    final photo = path == null ? null : File(path);
    final hasPhoto = photo?.existsSync() ?? false;

    return OnboardingStepScaffold(
      progress: flow.progress,
      onBack: controller.back,
      onSkip: widget.onSkip,
      ctaLabel: 'Continue',
      onCta: controller.next,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Capture the beginning of your journey.',
            style: OnboardingType.headline,
          ),
          const SizedBox(height: 10),
          Text(
            'We\'ll remind you how far you\'ve come when you need '
            'motivation the most. This photo never leaves your device.',
            style: OnboardingType.body,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: hasPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.file(photo!, fit: BoxFit.cover),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: OnboardingColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: OnboardingColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 44,
                          color: OnboardingColors.textFaint,
                        ),
                        const SizedBox(height: 14),
                        Text('Add your Day One photo',
                            style: OnboardingType.cardTitle),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: _picking ? null : () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _picking ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: OnboardingColors.textSecondary,
        side: BorderSide(color: OnboardingColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
