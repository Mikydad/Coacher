import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../application/goal_templates.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_template.dart';
import 'goal_editor_screen.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/bento_category_card.dart';

/// Entry point for creating a goal — pick a popular template (bento mosaic)
/// or start from a blank Custom Goal.
class GoalTemplatePickerScreen extends StatelessWidget {
  const GoalTemplatePickerScreen({super.key});

  static const routeName = '/goals/templates';

  void _openEditor(BuildContext context, GoalTemplate template) {
    Navigator.pushReplacementNamed(
      context,
      GoalEditorScreen.routeName,
      arguments: GoalEditorArgs(template: template),
    );
  }

  static IconData _iconFor(String id) => switch (id) {
    'study' => CupertinoIcons.book_fill,
    'fitness' => CupertinoIcons.flame_fill,
    'learn_skill' => CupertinoIcons.lightbulb_fill,
    'read_books' => CupertinoIcons.bookmark_fill,
    'focus' => CupertinoIcons.scope,
    _ => CupertinoIcons.sparkles,
  };

  static String? _subtitle(GoalTemplate t) {
    if (t.measurement == null) return null;
    final target = t.targetValue?.round() ?? 0;
    final unit = switch (t.measurement) {
      MeasurementKind.minutes => 'min',
      MeasurementKind.sessions => 'sessions',
      MeasurementKind.count => t.customLabel ?? 'count',
      MeasurementKind.distance => 'km',
      MeasurementKind.custom => t.customLabel ?? 'units',
      null => '',
    };
    return '$target $unit · ${GoalCategories.label(t.categoryId ?? '')}';
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final t in goalTemplates) t.id: t};

    BentoCategoryCard card(String id, Color color, {bool hero = false}) {
      final t = byId[id]!;
      return BentoCategoryCard(
        color: color,
        icon: _iconFor(id),
        label: t.label,
        subtitle: _subtitle(t),
        hero: hero,
        onTap: () => _openEditor(context, t),
      );
    }

    final custom = byId['custom']!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.fg70),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'NEW GOAL',
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popular goals',
              style: TextStyle(
                color: AppColors.fg,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a starting point — you can change anything on the '
              'next screen.',
              style: TextStyle(color: AppColors.fg54, height: 1.3),
            ),
            const SizedBox(height: 16),
            // Bento mosaic: Study hero on top, then two side-by-side pairs.
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: card('study', BentoPalette.yellow, hero: true),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(child: card('fitness', BentoPalette.orange)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: card('learn_skill', BentoPalette.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    flex: 5,
                    child: Row(
                      children: [
                        Expanded(
                          child: card('read_books', BentoPalette.purple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: card('focus', BentoPalette.blue)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BentoPillButton(
              label: custom.label,
              onTap: () => _openEditor(context, custom),
              color: AppColors.surfaceCard,
              textColor: AppColors.fg,
            ),
          ],
        ),
      ),
    );
  }
}
