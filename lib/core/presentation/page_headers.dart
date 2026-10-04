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
    AppColors.bindTheme(context);
    return Text(text.toUpperCase(), style: style);
  }
}

/// In-page section heading — one step below nothing: the loudest text on the
/// page. Optional [subtitle] renders muted below; [trailing] sits at the end
/// of the title row (counts, chevrons, help dots).
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.trailing,
    this.hero = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Card-heading size (24px bold) for the one card on a page that carries
  /// a headline rather than a label — Home's "1 task needs you". Everything
  /// else stays at [style].
  final bool hero;

  static TextStyle get style => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  static TextStyle get heroStyle => TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.3,
  );

  static TextStyle get subtitleStyle =>
      TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.3);

  @override
  Widget build(BuildContext context) {
    AppColors.bindTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: hero ? heroStyle : style)),
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
