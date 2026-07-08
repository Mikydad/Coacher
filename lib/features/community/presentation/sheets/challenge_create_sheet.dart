import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/keyboard_dismiss.dart';
import '../../../../core/utils/stable_id.dart';
import '../../application/challenge_providers.dart';
import '../../domain/models/challenge.dart';

import '../../../../core/presentation/app_colors.dart';

class ChallengeCreateSheet extends ConsumerStatefulWidget {
  const ChallengeCreateSheet({super.key, required this.circleId});

  final String circleId;

  @override
  ConsumerState<ChallengeCreateSheet> createState() =>
      _ChallengeCreateSheetState();
}

class _ChallengeCreateSheetState extends ConsumerState<ChallengeCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetController = TextEditingController();
  final _unitController = TextEditingController();

  ChallengeMode _mode = ChallengeMode.competition;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart
        ? DateTime.now()
        : _startDate.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: Colors.black,
            surface: AppColors.surfaceCard,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 7));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final now = DateTime.now().millisecondsSinceEpoch;
      final challenge = Challenge(
        id: StableId.generate('challenge'),
        circleId: widget.circleId,
        creatorId: user.uid,
        title: _titleController.text.trim(),
        mode: _mode,
        status: ChallengeStatus.pending,
        targetValue: int.tryParse(_targetController.text.trim()) ?? 1,
        unit: _unitController.text.trim(),
        memberProgress: const {},
        teamTotal: 0,
        startsAtMs: _startDate.millisecondsSinceEpoch,
        endsAtMs: _endDate.millisecondsSinceEpoch,
        createdAtMs: now,
        updatedAtMs: now,
      );

      await ref.read(challengeRepositoryProvider).createChallenge(challenge);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge submitted — waiting for member votes'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create challenge: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: KeyboardDismissOnTap(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.fg.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New challenge',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    _Label('Challenge title'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: AppColors.textPrimary),
                      onTapOutside: (_) => dismissKeyboard(context),
                      decoration: _inputDeco('e.g. Run 30 miles this month'),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.length < 3) return 'At least 3 characters';
                        if (s.length > 60) return 'Max 60 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Mode
                    _Label('Mode'),
                    const SizedBox(height: 8),
                    SegmentedButton<ChallengeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ChallengeMode.competition,
                          label: Text('Competition'),
                          icon: Icon(Icons.emoji_events_rounded),
                        ),
                        ButtonSegment(
                          value: ChallengeMode.team,
                          label: Text('Team'),
                          icon: Icon(Icons.group_rounded),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (s) =>
                          setState(() => _mode = s.first),
                      style: _segmentStyle(),
                    ),
                    const SizedBox(height: 16),

                    // Target + unit
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Target'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _targetController,
                                style: TextStyle(color: AppColors.textPrimary),
                                onTapOutside: (_) => dismissKeyboard(context),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _inputDeco('30'),
                                validator: (v) {
                                  final n = int.tryParse(v ?? '');
                                  if (n == null || n <= 0) {
                                    return 'Enter a number > 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Label('Unit'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _unitController,
                                style: TextStyle(color: AppColors.textPrimary),
                                onTapOutside: (_) => dismissKeyboard(context),
                                decoration: _inputDeco('miles / sessions'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date range
                    _Label('Duration'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _DateButton(
                            label: 'Start',
                            date: _startDate,
                            onTap: () => _pickDate(isStart: true),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '→',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        Expanded(
                          child: _DateButton(
                            label: 'End',
                            date: _endDate,
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.onAccent,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Submit challenge',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: AppColors.danger),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  ButtonStyle _segmentStyle() => ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.selected)) {
        return AppColors.accent;
      }
      return AppColors.surfaceCard;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((s) {
      if (s.contains(WidgetState.selected)) return Colors.black;
      return AppColors.textMuted;
    }),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = '${date.day}/${date.month}/${date.year}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
                Text(
                  formatted,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
