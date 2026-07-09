import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../application/feedback_submit_service.dart';
import '../domain/models/feedback_report.dart';

const _typeLabels = {
  FeedbackType.bug: 'Bug',
  FeedbackType.feature: 'Feature idea',
  FeedbackType.question: 'Question',
  FeedbackType.other: 'Other',
};

/// Bottom sheet opened by the tester bug bubble: screenshot preview with an
/// include/exclude toggle, type chips (Bug preselected), description, Send.
class TesterReportSheet extends ConsumerStatefulWidget {
  const TesterReportSheet({
    super.key,
    required this.screenshot,
    required this.contextSnapshot,
  });

  /// PNG of the moment the bubble was tapped; null when capture failed.
  final Uint8List? screenshot;
  final Map<String, String> contextSnapshot;

  @override
  ConsumerState<TesterReportSheet> createState() => _TesterReportSheetState();
}

class _TesterReportSheetState extends ConsumerState<TesterReportSheet> {
  final TextEditingController _messageController = TextEditingController();
  FeedbackType _type = FeedbackType.bug;
  bool _includeScreenshot = true;
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
          .submit(
            type: _type,
            message: message,
            screenshotBytes: _includeScreenshot ? widget.screenshot : null,
            contextOverride: widget.contextSnapshot,
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Report sent — thank you!')),
      );
      navigator.pop();
    } on FeedbackRateLimitedException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Please wait ${e.secondsRemaining}s before sending another '
            'report.',
          ),
        ),
      );
      if (mounted) setState(() => _submitting = false);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not send the report. Please try again.'),
        ),
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _messageController.text.trim().isNotEmpty && !_submitting;
    final screenshot = widget.screenshot;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSoft.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report a problem',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fg,
                ),
              ),
              const SizedBox(height: 16),
              if (screenshot != null) ...[
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        screenshot,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Include screenshot',
                        style: TextStyle(fontSize: 14, color: AppColors.fg),
                      ),
                    ),
                    Switch(
                      value: _includeScreenshot,
                      activeThumbColor: AppColors.accent,
                      onChanged: (v) => setState(() => _includeScreenshot = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
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
                      backgroundColor: AppColors.inkWarm,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _type == type
                            ? AppColors.onAccent
                            : AppColors.fg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                onChanged: (_) => setState(() {}),
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: FeedbackReport.maxMessageLength,
                style: TextStyle(fontSize: 14, color: AppColors.fg),
                decoration: InputDecoration(
                  hintText: 'What went wrong?',
                  hintStyle: TextStyle(color: AppColors.textSoft),
                  counterStyle: TextStyle(color: AppColors.textSoft),
                  filled: true,
                  fillColor: AppColors.inkWarm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                          'Send report',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
