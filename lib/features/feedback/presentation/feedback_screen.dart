import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/presentation/app_colors.dart';
import '../../community/data/circle_proof_storage.dart'
    show imageExtensionFromPath, contentTypeForImageExtension;
import '../../settings/presentation/settings_page_scaffold.dart';
import '../application/feedback_submit_service.dart';
import '../domain/models/feedback_report.dart';

const _typeLabels = {
  FeedbackType.bug: 'Bug',
  FeedbackType.feature: 'Feature idea',
  FeedbackType.question: 'Question',
  FeedbackType.other: 'Other',
};

/// All-user feedback form, reached from Profile → Send Feedback.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  static const routeName = '/feedback';

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final TextEditingController _messageController = TextEditingController();
  FeedbackType _type = FeedbackType.bug;
  bool _submitting = false;
  Uint8List? _screenshotBytes;
  String _screenshotContentType = 'image/jpeg';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    // Same compression as the circle chat proof picker.
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final ext = imageExtensionFromPath(picked.path, mimeType: picked.mimeType);
    if (!mounted) return;
    setState(() {
      _screenshotBytes = bytes;
      _screenshotContentType = contentTypeForImageExtension(ext);
    });
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(feedbackSubmitServiceProvider)
          .submit(
            type: _type,
            message: message,
            screenshotBytes: _screenshotBytes,
            screenshotContentType: _screenshotContentType,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Feedback sent — thank you!')),
      );
      if (navigator.canPop()) navigator.pop();
    } on FeedbackRateLimitedException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Please wait ${e.secondsRemaining}s before sending more feedback.',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not send feedback. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _messageController.text.trim().isNotEmpty && !_submitting;
    return SettingsPageScaffold(
      title: 'Send Feedback',
      children: [
        const SettingsSectionHeader(label: 'What is it about?'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in FeedbackType.values)
              ChoiceChip(
                label: Text(_typeLabels[type]!),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
                selectedColor: AppColors.accent,
                backgroundColor: kSettingsSurfaceHigh,
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _type == type
                      ? AppColors.onAccent
                      : kSettingsOnSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 24),
        const SettingsSectionHeader(label: 'Tell us more'),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          onChanged: (_) => setState(() {}),
          minLines: 5,
          maxLines: 10,
          maxLength: FeedbackReport.maxMessageLength,
          style: TextStyle(fontSize: 14, color: kSettingsOnSurface),
          decoration: InputDecoration(
            hintText: 'What happened? What did you expect?',
            hintStyle: TextStyle(color: kSettingsOnSurfaceVariant),
            counterStyle: TextStyle(color: kSettingsOnSurfaceVariant),
            filled: true,
            fillColor: kSettingsSurfaceHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_screenshotBytes == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickScreenshot,
              icon: Icon(
                Icons.add_photo_alternate_outlined,
                size: 20,
                color: AppColors.accent,
              ),
              label: Text(
                'Add screenshot (optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  _screenshotBytes!,
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Screenshot attached',
                  style: TextStyle(
                    fontSize: 13,
                    color: kSettingsOnSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _screenshotBytes = null),
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: kSettingsOnSurfaceVariant,
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: canSend ? _send : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
            ),
            child: _submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onAccent,
                    ),
                  )
                : const Text(
                    'Send',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your app version, device and screen info are attached '
          'automatically so we can fix things faster.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: kSettingsOnSurfaceVariant),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
