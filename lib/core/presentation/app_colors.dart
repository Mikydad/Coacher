import 'package:flutter/material.dart';

/// Global design tokens for the app's dark "Obsidian Pulse" palette.
///
/// Single source of truth for every color used at more than a handful of
/// call sites. Rules:
///
/// - New UI code references these tokens, never raw `Color(0x...)` literals.
///   ALL colors live in this file — including single-use ones (see the
///   "One-off colors" section below, where each entry documents which file
///   uses it and for what).
/// - The lime shades ([accent] / [accentDim] / [accentBright]) are distinct
///   on purpose — do not "fix" them into one value.
/// - Feature palettes (AddTaskColors, GoalEditorColors, ...) alias these
///   tokens; add feature-local names there, but the value must come from here
///   when it exists.
abstract final class AppColors {
  // Brand limes.
  static const accent = Color(0xFFB7FF00);
  static const accentDim = Color(0xFFB2ED00);
  static const accentBright = Color(0xFFBEFC00);
  static const accentDeep = Color(0xFF445D00);

  // Secondary accents.
  static const cyan = Color(0xFF00E3FD);
  static const cyanDeep = Color(0xFF00CFFF);
  static const mint = Color(0xFF00FF9F);
  static const success = Color(0xFF4ADE80);
  static const violet = Color(0xFF7B61FF);
  static const violetSoft = Color(0xFF6C63FF);
  static const pink = Color(0xFFFF4D9E);
  static const coral = Color(0xFFFF7351);
  static const orange = Color(0xFFFF8C42);
  static const amber = Color(0xFFFFA726);
  static const amberDeep = Color(0xFFFF9933);
  static const yellow = Color(0xFFFFD600);
  static const danger = Color(0xFFFF4D4D);

  // Text.
  static const textPrimary = Color(0xFFF0F4FF);
  static const textMuted = Color(0xFF8A8FA8);
  static const textSoft = Color(0xFFADAAAA);
  static const textGray = Color(0xFF888888);
  static const textFaint = Color(0xFF666666);
  static const textDim = Color(0xFF444444);

  // Surfaces — blue-tinted slate family (home, community, analytics).
  static const scaffold = Color(0xFF050806);
  static const surfaceCard = Color(0xFF1C2029);
  static const surfaceDark = Color(0xFF14171C);
  static const surfaceSlate = Color(0xFF2A2F3D);
  static const surfaceMuted = Color(0xFF1A1C1F);
  static const surfacePanel = Color(0xFF111317);
  static const surfaceDeep = Color(0xFF0D0F12);

  // Surfaces — neutral obsidian family (add-task, editors, sheets).
  static const ink = Color(0xFF0E0E0E);
  static const inkCard = Color(0xFF1A1A1A);
  static const inkWarm = Color(0xFF201F1F);
  static const inkElevated = Color(0xFF262626);
  static const inkSoft = Color(0xFF2E2E2E);
  static const inkDeep = Color(0xFF131313);

  // ==========================================================================
  // One-off colors.
  //
  // Each color below is used in only one or two places. They live here so a
  // theme change never has to hunt through feature files. Every entry's
  // comment says WHERE it is used and WHAT it paints — keep that comment
  // up to date if you add a call site or repurpose the color.
  // ==========================================================================

  // --- Lime tints (derived from the brand lime — update these together with
  // --- [accent] on any rebrand, or the mix of shades will look off).
  /// Pale lime. profile_screen.dart (_kPrimary), progress_design_tokens.dart (primary).
  static const limeCream = Color(0xFFEAFFB8);

  /// Soft lime text. auth_landing_screen.dart, email_verification_banner.dart.
  static const limeSoft = Color(0xFFD4F08A);

  /// Olive lime. goal_card.dart — "productivity" goal-category color.
  static const limeOlive = Color(0xFF7BAF2A);

  /// Very dark lime. profile_screen.dart (_kOnPrimaryFixed — text on lime).
  static const limeShadow = Color(0xFF354900);

  /// Near-black lime wash. proactive_suggestion_card.dart — card background.
  static const limeInk = Color(0xFF1A2800);

  /// Near-black lime wash. auth_landing_screen.dart — panel background.
  static const limeInkDim = Color(0xFF0D1A00);

  /// Near-black lime wash. email_verification_banner.dart — banner background.
  static const limeInkDeep = Color(0xFF0A1600);

  // --- Score / status accents (traffic-light scale shared by
  // --- home_screen.dart, analytics_progress_screen.dart, coaching_focus_card.dart).
  /// Mid-tier score (>= 50%).
  static const scoreAmber = Color(0xFFFFD54F);

  /// Low-tier score.
  static const scoreCoral = Color(0xFFFF6D4E);

  /// "On track" status. ai_assistant_screen.dart.
  static const statusGreen = Color(0xFF4CAF50);

  /// "Needs attention" status. ai_assistant_screen.dart.
  static const statusOrange = Color(0xFFFF9800);

  /// Soft teal accent. coaching_focus_card.dart.
  static const tealSoft = Color(0xFF80CBC4);

  // --- Goal-category colors (goal_card.dart switch on GoalCategories;
  // --- tealDeep is also GoalEditorColors.cyan in goal_editor_widgets.dart).
  static const categoryTeal = Color(0xFF2A9B8B); // mental clarity
  static const categoryBlue = Color(0xFF3B6FD4); // study
  static const categoryPurple = Color(0xFF7B4FBF); // focus
  static const categoryBrown = Color(0xFF8B6B3D); // habits
  static const categoryBurntOrange = Color(0xFFE07B2A); // fitness

  // --- Community accents.
  /// Trophy / winner gold. circle_info_view.dart, circle_challenges_view.dart.
  static const gold = Color(0xFFFFD700);

  /// Info icons. circle_challenges_view.dart.
  static const periwinkle = Color(0xFF7B9CFF);

  // --- Whites & grays.
  /// Pure white. Palette "onSurface" in settings_page_scaffold.dart,
  /// profile_screen.dart, progress_design_tokens.dart, add_task_ui.dart.
  static const white = Color(0xFFFFFFFF);

  /// Bright gray text. planned_changes_card.dart.
  static const grayBright = Color(0xFFE0E0E0);

  /// Light gray text. ai_assistant_screen.dart.
  static const grayLight = Color(0xFFCCCCCC);

  /// iOS system gray. attention_mode_widgets.dart (sheet label).
  static const grayIos = Color(0xFF8E8E93);

  /// Slate gray labels. goal_editor_widgets.dart, plan_tomorrow_widgets.dart.
  static const graySlate = Color(0xFF6B7280);

  /// Darker slate hint text. goal_editor_widgets.dart.
  static const graySlateDeep = Color(0xFF4B5563);

  /// Close-button icons. auth_landing_screen.dart, email_verification_banner.dart.
  static const gray55 = Color(0xFF555555);

  /// Input borders. proactive_suggestion_section.dart, ai_input_card.dart.
  static const gray3A = Color(0xFF3A3A3A);

  /// Borders / sheet drag handle. account_settings_screen.dart, attention_mode_widgets.dart.
  static const gray33 = Color(0xFF333333);

  /// Dividers. account_settings_screen.dart, auth_google_sign_in_button.dart.
  static const gray2A = Color(0xFF2A2A2A);

  /// Warm faint gray. add_task_ui.dart (AddTaskColors.faint).
  static const grayWarm = Color(0xFF6B6767);

  // --- One-off dark surfaces (named by hex so the value is obvious;
  // --- candidates for consolidation into the surface/ink families above).
  /// timer_session_screen.dart — screen background.
  static const dark0B0D10 = Color(0xFF0B0D10);

  /// circle_challenges_view.dart — sheet background.
  static const dark0D1117 = Color(0xFF0D1117);

  /// coaching_style_selection_screen.dart — screen background.
  static const dark0F0F1A = Color(0xFF0F0F1A);

  /// Input fills. account_settings_screen.dart, goal_editor_widgets.dart, add_task_ui.dart.
  static const dark111111 = Color(0xFF111111);

  /// attention_mode_widgets.dart — sheet background.
  static const dark121212 = Color(0xFF121212);

  /// goal_counter_sheet.dart — sheet background.
  static const dark151718 = Color(0xFF151718);

  /// sleep_task_ios_guidance.dart — dialog background.
  static const dark181818 = Color(0xFF181818);

  /// add_task_ui.dart — AddTaskColors.card.
  static const dark1A1919 = Color(0xFF1A1919);

  /// home_screen.dart — card background.
  static const dark1A1D22 = Color(0xFF1A1D22);

  /// ai_pulse_banner.dart — gradient start.
  static const dark1A2535 = Color(0xFF1A2535);

  /// Borders. auth_landing_screen.dart, auth_text_field.dart (disabled).
  static const dark1E1E1E = Color(0xFF1E1E1E);

  /// coaching_style_selection_screen.dart — card background.
  static const dark1E1E2E = Color(0xFF1E1E2E);

  /// ai_assistant_screen.dart — chip background.
  static const dark1E2A2A = Color(0xFF1E2A2A);

  /// timer_session_screen.dart — control background.
  static const dark1F2026 = Color(0xFF1F2026);

  /// goal_editor_widgets.dart — GoalEditorColors.surfaceRaised.
  static const dark222528 = Color(0xFF222528);

  /// Borders/cards. goal_counter_sheet.dart, category_chip_row.dart, goal_editor_widgets.dart.
  static const dark2A2D32 = Color(0xFF2A2D32);

  /// coaching_focus_card.dart — chip background.
  static const dark2A2D33 = Color(0xFF2A2D33);

  /// Buttons. timer_session_screen.dart, focus_selection_screen.dart.
  static const dark2B2D31 = Color(0xFF2B2D31);

  /// progress_design_tokens.dart — surfaceBright.
  static const dark2C2C2C = Color(0xFF2C2C2C);

  // --- Alpha overlays (leading byte is opacity, not color).
  /// White at 8% — hairline borders. add_task_ui.dart (AddTaskColors.border).
  static const whiteBorder8 = Color(0x14FFFFFF);

  /// White at 20% — glow paint. home_screen.dart.
  static const whiteGlow20 = Color(0x33FFFFFF);

  /// Cyan at 20% — border. ai_assistant_screen.dart.
  static const cyanBorder20 = Color(0x3300E3FD);

  /// Ink at 50% — card scrim. attention_mode_widgets.dart (cardOverlay).
  static const blackScrim50 = Color(0x801A1A1A);
}
