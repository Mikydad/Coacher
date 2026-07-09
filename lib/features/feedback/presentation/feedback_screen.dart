import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
          .submit(type: _type, message: message);
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
