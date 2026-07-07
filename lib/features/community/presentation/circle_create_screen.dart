import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/keyboard_dismiss.dart';
import '../../../core/utils/stable_id.dart';
import '../../../core/di/providers.dart';
import '../application/circle_providers.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';
import 'circle_detail_screen.dart';

import '../../../core/presentation/app_colors.dart';

const _kCategories = [
  'fitness',
  'learning',
  'business',
  'reading',
  'productivity',
  'other',
];

class CircleCreateScreen extends ConsumerStatefulWidget {
  const CircleCreateScreen({super.key});

  static const routeName = '/community/create';

  @override
  ConsumerState<CircleCreateScreen> createState() => _CircleCreateScreenState();
}

class _CircleCreateScreenState extends ConsumerState<CircleCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory;
  JoinPolicy _joinPolicy = JoinPolicy.open;
  CircleVisibility _visibility = CircleVisibility.public;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a category.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');

      final circleId = StableId.generate('circle');
      final now = DateTime.now().millisecondsSinceEpoch;

      final circle = AccountabilityCircle(
        id: circleId,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        category: _selectedCategory!,
        joinPolicy: _joinPolicy,
        visibility: _visibility,
        creatorId: user.uid,
        moderatorIds: [user.uid],
        memberCount: 1,
        timezone: DateTime.now().timeZoneName,
        createdAtMs: now,
        updatedAtMs: now,
      );

      await ref
          .read(userCircleMembershipServiceProvider)
          .createCircleWithCreator(circle);

      invalidateCircleScopedProviders(ref);

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          CircleDetailScreen.routeName,
          arguments: circleId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create circle: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Create circle',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: KeyboardDismissOnTap(
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            children: [
              _SectionLabel('Circle name'),
              const SizedBox(height: 8),
              _buildNameField(),
              const SizedBox(height: 24),
              _SectionLabel('Description (optional)'),
              const SizedBox(height: 8),
              _buildDescField(),
              const SizedBox(height: 24),
              _SectionLabel('Category'),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              _SectionLabel('Join policy'),
              const SizedBox(height: 12),
              _buildJoinPolicyToggle(),
              const SizedBox(height: 24),
              _SectionLabel('Visibility'),
              const SizedBox(height: 12),
              _buildVisibilityToggle(),
              const SizedBox(height: 40),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: AppColors.textPrimary),
      maxLength: 40,
      onTapOutside: (_) => dismissKeyboard(context),
      decoration: _inputDecoration('e.g. Morning runners'),
      validator: (v) {
        final s = v?.trim() ?? '';
        if (s.length < 3) return 'Name must be at least 3 characters';
        if (s.length > 40) return 'Name must be 40 characters or less';
        return null;
      },
    );
  }

  Widget _buildDescField() {
    return TextFormField(
      controller: _descController,
      style: const TextStyle(color: AppColors.textPrimary),
      maxLines: 3,
      maxLength: 200,
      onTapOutside: (_) => dismissKeyboard(context),
      decoration: _inputDecoration('What is this circle about?'),
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kCategories.map((cat) {
        final selected = _selectedCategory == cat;
        return ChoiceChip(
          label: Text(
            cat[0].toUpperCase() + cat.substring(1),
            style: TextStyle(
              color: selected ? Colors.black : AppColors.textMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          selected: selected,
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.surfaceCard,
          side: BorderSide(
            color: selected ? AppColors.accent : Colors.white.withOpacity(0.06),
          ),
          onSelected: (_) => setState(() => _selectedCategory = cat),
        );
      }).toList(),
    );
  }

  Widget _buildJoinPolicyToggle() {
    return SegmentedButton<JoinPolicy>(
      segments: const [
        ButtonSegment(
          value: JoinPolicy.open,
          label: Text('Open'),
          icon: Icon(Icons.lock_open_rounded),
        ),
        ButtonSegment(
          value: JoinPolicy.requestApproval,
          label: Text('Approval'),
          icon: Icon(Icons.how_to_reg_rounded),
        ),
      ],
      selected: {_joinPolicy},
      onSelectionChanged: (s) => setState(() => _joinPolicy = s.first),
      style: _segmentStyle(),
    );
  }

  Widget _buildVisibilityToggle() {
    return SegmentedButton<CircleVisibility>(
      segments: const [
        ButtonSegment(
          value: CircleVisibility.public,
          label: Text('Public'),
          icon: Icon(Icons.public_rounded),
        ),
        ButtonSegment(
          value: CircleVisibility.private,
          label: Text('Private'),
          icon: Icon(Icons.visibility_off_rounded),
        ),
      ],
      selected: {_visibility},
      onSelectionChanged: (s) => setState(() => _visibility = s.first),
      style: _segmentStyle(),
    );
  }

  Widget _buildSaveButton() {
    return FilledButton(
      onPressed: _saving ? null : _save,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : const Text(
              'Create circle',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      counterStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    );
  }

  ButtonStyle _segmentStyle() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accent;
        }
        return AppColors.surfaceCard;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black;
        return AppColors.textMuted;
      }),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }
}
