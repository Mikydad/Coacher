import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../application/circle_providers.dart';
import '../../domain/models/accountability_circle.dart';
import '../../domain/models/circle_enums.dart';

/// Edit a circle's metadata (2026-09-24; replaces the "coming soon" stub):
/// name, description, category, join policy and Public/Private. Writes only
/// the fields that changed — the rules refuse any write that touches
/// `memberCount` or `creatorId`, which a whole-document merge would carry.
///
/// Optimistic-then-honest: the sheet closes at once, the circle stream
/// echoes the change, and a rejection comes back as a snackbar.
class CircleEditSheet extends ConsumerStatefulWidget {
  const CircleEditSheet({super.key, required this.circle});

  final AccountabilityCircle circle;

  static Future<void> show(BuildContext context, AccountabilityCircle circle) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacePanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CircleEditSheet(circle: circle),
    );
  }

  @override
  ConsumerState<CircleEditSheet> createState() => _CircleEditSheetState();
}

class _CircleEditSheetState extends ConsumerState<CircleEditSheet> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _category;
  late JoinPolicy _joinPolicy;
  late CircleVisibility _visibility;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final c = widget.circle;
    _name = TextEditingController(text: c.name);
    _description = TextEditingController(text: c.description ?? '');
    _category = c.category;
    _joinPolicy = c.joinPolicy;
    _visibility = c.visibility;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  /// The fields that differ from the stored circle — what gets written.
  Map<String, dynamic> get _changes {
    final c = widget.circle;
    final name = _name.text.trim();
    final description = _description.text.trim();
    return {
      if (name != c.name) 'name': name,
      if (description != (c.description ?? '')) 'description': description,
      if (_category != c.category) 'category': _category,
      if (_joinPolicy != c.joinPolicy) 'joinPolicy': _joinPolicy.storageValue,
      if (_visibility != c.visibility) 'visibility': _visibility.storageValue,
    };
  }

  void _save() {
    final name = _name.text.trim();
    if (name.length < 3 || name.length > 40) {
      setState(() => _nameError = 'Name must be 3–40 characters.');
      return;
    }
    final changes = _changes;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (changes.isEmpty) return;
    unawaited(
      ref
          .read(circleRepositoryProvider)
          .updateCircleFields(widget.circle.id, changes)
          .then((_) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Circle updated.')),
            );
          })
          .catchError((Object _) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Could not update the circle. Try again.'),
              ),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit circle',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Name',
                errorText: _nameError,
                counterText: '',
              ),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            _Label('CATEGORY'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in kCircleCategories)
                  ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (_) => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _Label('WHO CAN JOIN'),
            const SizedBox(height: 8),
            SegmentedButton<JoinPolicy>(
              segments: const [
                ButtonSegment(value: JoinPolicy.open, label: Text('Open')),
                ButtonSegment(
                  value: JoinPolicy.requestApproval,
                  label: Text('Approval'),
                ),
              ],
              selected: {_joinPolicy},
              onSelectionChanged: (s) => setState(() => _joinPolicy = s.first),
            ),
            const SizedBox(height: 16),
            _Label('VISIBILITY'),
            const SizedBox(height: 8),
            SegmentedButton<CircleVisibility>(
              segments: const [
                ButtonSegment(
                  value: CircleVisibility.public,
                  label: Text('Public'),
                ),
                ButtonSegment(
                  value: CircleVisibility.private,
                  label: Text('Private'),
                  icon: Icon(Icons.visibility_off_rounded),
                ),
              ],
              selected: {_visibility},
              onSelectionChanged: (s) => setState(() => _visibility = s.first),
            ),
            const SizedBox(height: 6),
            Text(
              _visibility == CircleVisibility.public
                  ? 'Anyone can find this circle in Discover.'
                  : 'Only people with an invite key can find and join.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
