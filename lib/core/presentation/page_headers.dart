import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide header hierarchy — three tiers, loudest wins in-page:
///
///  1. [PageTitle] — AppBar chrome: quiet small caps. The page name recedes
///     so content leads.
///  2. [SectionHeader] — the loudest text on a page (18px extra-bold).
///  3. Micro-labels — 11px uppercase tracked labels (feature-local, e.g.
///     `GoalEditorSectionLabel`), for grouping controls inside a section.
///
/// Screens with bespoke header layouts can reuse [PageTitle.style] /
/// [SectionHeader.style] directly so the type scale stays identical.

/// Quiet small-caps page title for `AppBar.title` (pair with
/// `centerTitle: true`).
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});

  final String text;

  static TextStyle get style => TextStyle(
    color: AppColors.fg70,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.8,
  );

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: style);
  }
}

/// In-page section heading — one step below nothing: the loudest text on the
/// page. Optional [subtitle] renders muted below; [trailing] sits at the end
/// of the title row (counts, chevrons, help dots).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  static TextStyle get style => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get subtitleStyle =>
      TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.3);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: style)),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: subtitleStyle),
        ],
      ],
    );
  }
}
