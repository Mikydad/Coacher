import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import '../../ai_assistant/presentation/ai_assistant_screen.dart';
import '../../memory/presentation/memory_knowledge_screen.dart';
import 'setting_row.dart';
import 'settings_page_scaffold.dart';

/// Coach & AI page (Profile reorg 2026-08-23): the coach entry point and
/// what SidePal has learned about you.
class CoachAiSettingsScreen extends StatelessWidget {
  const CoachAiSettingsScreen({super.key});

  static const routeName = '/settings/coach-ai';

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: 'Coach & AI',
      children: [
        const SettingsSectionHeader(label: 'Your coach'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Column(
            children: [
              SettingRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Coach AI',
                subtitle: 'Your coach, from anywhere',
                trailing: const SettingRowChevron(),
                onTap: () => showCoachAiSheet(context),
              ),
              SettingRow(
                icon: Icons.psychology_outlined,
                title: 'What SidePal knows',
                subtitle: 'Remembered facts, people & summaries',
                trailing: const SettingRowChevron(),
                onTap: () => Navigator.pushNamed(
                  context,
                  MemoryKnowledgeScreen.routeName,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'What SidePal knows is fully yours — review, edit, or delete any '
          'remembered fact at any time.',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSoft.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
