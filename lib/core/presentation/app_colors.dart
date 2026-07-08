import 'package:flutter/material.dart';

/// Design tokens for "Obsidian Pulse", one value per brightness.
///
/// [AppPalette.dark] is the original dark theme (values unchanged from the
/// pre-light-mode `AppColors` constants). [AppPalette.light] implements
/// "Obsidian Pulse Light" (PRD/Light_Screen_Design/DESIGN.md):
/// white/gray tonal surfaces, ink text, and the neon lime reserved for
/// primary actions — always with dark text on it.
///
/// Rules (unchanged from the constants era):
/// - UI code references [AppColors] tokens, never raw `Color(0x...)`.
/// - The lime shades (accent/accentDim/accentBright) are distinct on purpose.
/// - Feature palettes (AddTaskColors, ...) alias these tokens.
/// - One-off tokens keep their usage documented at the field (see below).
class AppPalette {
  const AppPalette({
    required this.accent,
    required this.accentDim,
    required this.accentBright,
    required this.accentDeep,
    required this.onAccent,
    required this.homeHeroCard,
    required this.cyan,
    required this.cyanDeep,
    required this.mint,
    required this.success,
    required this.violet,
    required this.violetSoft,
    required this.pink,
    required this.coral,
    required this.orange,
    required this.amber,
    required this.amberDeep,
    required this.yellow,
    required this.danger,
    required this.textPrimary,
    required this.textMuted,
    required this.textSoft,
    required this.textGray,
    required this.textFaint,
    required this.textDim,
    required this.fg,
    required this.fg70,
    required this.fg60,
    required this.fg54,
    required this.fg38,
    required this.fg24,
    required this.fg12,
    required this.fg10,
    required this.scaffold,
    required this.surfaceCard,
    required this.surfaceDark,
    required this.surfaceSlate,
    required this.surfaceMuted,
    required this.surfacePanel,
    required this.surfaceDeep,
    required this.ink,
    required this.inkCard,
    required this.inkWarm,
    required this.inkElevated,
    required this.inkSoft,
    required this.inkDeep,
    required this.actionTileActive,
    required this.onActionTileActive,
    required this.actionTile,
    required this.onActionTile,
    required this.limeCream,
    required this.limeSoft,
    required this.limeOlive,
    required this.limeShadow,
    required this.limeInk,
    required this.limeInkDim,
    required this.limeInkDeep,
    required this.scoreAmber,
    required this.scoreCoral,
    required this.statusGreen,
    required this.statusOrange,
    required this.tealSoft,
    required this.categoryTeal,
    required this.categoryBlue,
    required this.categoryPurple,
    required this.categoryBrown,
    required this.categoryBurntOrange,
    required this.gold,
    required this.periwinkle,
    required this.white,
    required this.grayBright,
    required this.grayLight,
    required this.grayIos,
    required this.graySlate,
    required this.graySlateDeep,
    required this.gray55,
    required this.gray3A,
    required this.gray33,
    required this.gray2A,
    required this.grayWarm,
    required this.dark0B0D10,
    required this.dark0D1117,
    required this.dark0F0F1A,
    required this.dark111111,
    required this.dark121212,
    required this.dark151718,
    required this.dark181818,
    required this.dark1A1919,
    required this.dark1A1D22,
    required this.dark1A2535,
    required this.dark1E1E1E,
    required this.dark1E1E2E,
    required this.dark1E2A2A,
    required this.dark1F2026,
    required this.dark222528,
    required this.dark2A2D32,
    required this.dark2A2D33,
    required this.dark2B2D31,
    required this.dark2C2C2C,
    required this.whiteBorder8,
    required this.whiteGlow20,
    required this.cyanBorder20,
    required this.blackScrim50,
  });

  // Brand limes.
  /// Active/highlight. Light: design `primary` olive — readable on white.
  final Color accent;
  final Color accentDim;

  /// Primary button bg (black text on it in BOTH modes).
  final Color accentBright;

  /// Text/icons ON the lime button.
  final Color accentDeep;

  /// Foreground for accent-filled chips/buttons. Dark mode's accent is
  /// bright lime → ink text; light mode's accent is dark olive → white.
  final Color onAccent;

  /// Home top analytics card — a touch dimmer than plain white cards.
  final Color homeHeroCard;
  // Secondary accents (light values darkened for white surfaces).
  final Color cyan;
  final Color cyanDeep;
  final Color mint;
  final Color success;
  final Color violet;
  final Color violetSoft;
  final Color pink;
  final Color coral;
  final Color orange;
  final Color amber;
  final Color amberDeep;
  final Color yellow;
  final Color danger;
  // Text.
  final Color textPrimary;
  final Color textMuted;
  final Color textSoft;
  final Color textGray;
  final Color textFaint;
  final Color textDim;
  // Foreground scale — replaces direct Colors.white* uses so light mode
  // can invert them (dark: white opacities, light: ink grays).
  final Color fg;
  final Color fg70;
  final Color fg60;
  final Color fg54;
  final Color fg38;
  final Color fg24;
  final Color fg12;
  final Color fg10;
  // Surfaces — blue-tinted slate family (home, community, analytics).
  final Color scaffold;
  final Color surfaceCard;
  final Color surfaceDark;
  final Color surfaceSlate;
  final Color surfaceMuted;
  final Color surfacePanel;
  final Color surfaceDeep;
  // Surfaces — neutral obsidian family (add-task, editors, sheets).
  final Color ink;
  final Color inkCard;
  final Color inkWarm;
  final Color inkElevated;
  final Color inkSoft;
  final Color inkDeep;
  // Quick-action tiles (home). Light per mock: active tile is ink with
  // white glyph; idle tiles are gray with ink glyphs. Dark inverts.
  final Color actionTileActive;
  final Color onActionTileActive;
  final Color actionTile;
  final Color onActionTile;
  // One-off: lime tints (rebrand together with accent).
  /// Used as TEXT on dark → olive text on light.
  final Color limeCream;
  final Color limeSoft;
  final Color limeOlive;

  /// Text ON lime — works in both modes.
  final Color limeShadow;

  /// Card wash: near-black lime → pale lime.
  final Color limeInk;
  final Color limeInkDim;
  final Color limeInkDeep;
  // One-off: score / status accents.
  final Color scoreAmber;
  final Color scoreCoral;
  final Color statusGreen;
  final Color statusOrange;
  final Color tealSoft;
  // One-off: goal-category colors.
  final Color categoryTeal;
  final Color categoryBlue;
  final Color categoryPurple;
  final Color categoryBrown;
  final Color categoryBurntOrange;
  // One-off: community accents.
  final Color gold;
  final Color periwinkle;
  // One-off: whites & grays (light values invert intensity).
  /// Palette onSurface text — ink on light.
  final Color white;
  final Color grayBright;
  final Color grayLight;
  final Color grayIos;
  final Color graySlate;
  final Color graySlateDeep;
  final Color gray55;
  final Color gray3A;
  final Color gray33;
  final Color gray2A;
  final Color grayWarm;
  // One-off dark surfaces (named by their DARK hex; light maps to the
  // equivalent white/gray so the name stays a stable identifier).
  final Color dark0B0D10;
  final Color dark0D1117;
  final Color dark0F0F1A;
  final Color dark111111;
  final Color dark121212;
  final Color dark151718;
  final Color dark181818;
  final Color dark1A1919;
  final Color dark1A1D22;
  final Color dark1A2535;
  final Color dark1E1E1E;
  final Color dark1E1E2E;
  final Color dark1E2A2A;
  final Color dark1F2026;
  final Color dark222528;
  final Color dark2A2D32;
  final Color dark2A2D33;
  final Color dark2B2D31;
  final Color dark2C2C2C;
  // One-off alpha overlays (leading byte is opacity).
  final Color whiteBorder8;
  final Color whiteGlow20;
  final Color cyanBorder20;

  /// Scrim — same in both modes.
  final Color blackScrim50;

  static const AppPalette dark = AppPalette(
    // Brand limes.
    accent: Color(0xFFB7FF00),
    accentDim: Color(0xFFB2ED00),
    accentBright: Color(0xFFBEFC00),
    accentDeep: Color(0xFF445D00),
    onAccent: Color(0xFF0E0E0E),
    homeHeroCard: Color(0xFF111317),
    // Secondary accents (light values darkened for white surfaces).
    cyan: Color(0xFF00E3FD),
    cyanDeep: Color(0xFF00CFFF),
    mint: Color(0xFF00FF9F),
    success: Color(0xFF4ADE80),
    violet: Color(0xFF7B61FF),
    violetSoft: Color(0xFF6C63FF),
    pink: Color(0xFFFF4D9E),
    coral: Color(0xFFFF7351),
    orange: Color(0xFFFF8C42),
    amber: Color(0xFFFFA726),
    amberDeep: Color(0xFFFF9933),
    yellow: Color(0xFFFFD600),
    danger: Color(0xFFFF4D4D),
    // Text.
    textPrimary: Color(0xFFF0F4FF),
    textMuted: Color(0xFF8A8FA8),
    textSoft: Color(0xFFADAAAA),
    textGray: Color(0xFF888888),
    textFaint: Color(0xFF666666),
    textDim: Color(0xFF444444),
    // Foreground scale — replaces direct Colors.white* uses so light mode
    // can invert them (dark: white opacities, light: ink grays).
    fg: Color(0xFFFFFFFF),
    fg70: Color(0xB3FFFFFF),
    fg60: Color(0x99FFFFFF),
    fg54: Color(0x8AFFFFFF),
    fg38: Color(0x61FFFFFF),
    fg24: Color(0x3DFFFFFF),
    fg12: Color(0x1FFFFFFF),
    fg10: Color(0x1AFFFFFF),
    // Surfaces — blue-tinted slate family (home, community, analytics).
    scaffold: Color(0xFF050806),
    surfaceCard: Color(0xFF1C2029),
    surfaceDark: Color(0xFF14171C),
    surfaceSlate: Color(0xFF2A2F3D),
    surfaceMuted: Color(0xFF1A1C1F),
    surfacePanel: Color(0xFF111317),
    surfaceDeep: Color(0xFF0D0F12),
    // Surfaces — neutral obsidian family (add-task, editors, sheets).
    ink: Color(0xFF0E0E0E),
    inkCard: Color(0xFF1A1A1A),
    inkWarm: Color(0xFF201F1F),
    inkElevated: Color(0xFF262626),
    inkSoft: Color(0xFF2E2E2E),
    inkDeep: Color(0xFF131313),
    // Quick-action tiles (home). Light per mock: active tile is ink with
    // white glyph; idle tiles are gray with ink glyphs. Dark inverts.
    actionTileActive: Color(0xFFB7FF00),
    onActionTileActive: Color(0xFF0E0E0E),
    actionTile: Color(0xFF1A1C1F),
    onActionTile: Color(0xFFB7FF00),
    // One-off: lime tints (rebrand together with accent).
    limeCream: Color(0xFFEAFFB8),
    limeSoft: Color(0xFFD4F08A),
    limeOlive: Color(0xFF7BAF2A),
    limeShadow: Color(0xFF354900),
    limeInk: Color(0xFF1A2800),
    limeInkDim: Color(0xFF0D1A00),
    limeInkDeep: Color(0xFF0A1600),
    // One-off: score / status accents.
    scoreAmber: Color(0xFFFFD54F),
    scoreCoral: Color(0xFFFF6D4E),
    statusGreen: Color(0xFF4CAF50),
    statusOrange: Color(0xFFFF9800),
    tealSoft: Color(0xFF80CBC4),
    // One-off: goal-category colors.
    categoryTeal: Color(0xFF2A9B8B),
    categoryBlue: Color(0xFF3B6FD4),
    categoryPurple: Color(0xFF7B4FBF),
    categoryBrown: Color(0xFF8B6B3D),
    categoryBurntOrange: Color(0xFFE07B2A),
    // One-off: community accents.
    gold: Color(0xFFFFD700),
    periwinkle: Color(0xFF7B9CFF),
    // One-off: whites & grays (light values invert intensity).
    white: Color(0xFFFFFFFF),
    grayBright: Color(0xFFE0E0E0),
    grayLight: Color(0xFFCCCCCC),
    grayIos: Color(0xFF8E8E93),
    graySlate: Color(0xFF6B7280),
    graySlateDeep: Color(0xFF4B5563),
    gray55: Color(0xFF555555),
    gray3A: Color(0xFF3A3A3A),
    gray33: Color(0xFF333333),
    gray2A: Color(0xFF2A2A2A),
    grayWarm: Color(0xFF6B6767),
    // One-off dark surfaces (named by their DARK hex; light maps to the
    // equivalent white/gray so the name stays a stable identifier).
    dark0B0D10: Color(0xFF0B0D10),
    dark0D1117: Color(0xFF0D1117),
    dark0F0F1A: Color(0xFF0F0F1A),
    dark111111: Color(0xFF111111),
    dark121212: Color(0xFF121212),
    dark151718: Color(0xFF151718),
    dark181818: Color(0xFF181818),
    dark1A1919: Color(0xFF1A1919),
    dark1A1D22: Color(0xFF1A1D22),
    dark1A2535: Color(0xFF1A2535),
    dark1E1E1E: Color(0xFF1E1E1E),
    dark1E1E2E: Color(0xFF1E1E2E),
    dark1E2A2A: Color(0xFF1E2A2A),
    dark1F2026: Color(0xFF1F2026),
    dark222528: Color(0xFF222528),
    dark2A2D32: Color(0xFF2A2D32),
    dark2A2D33: Color(0xFF2A2D33),
    dark2B2D31: Color(0xFF2B2D31),
    dark2C2C2C: Color(0xFF2C2C2C),
    // One-off alpha overlays (leading byte is opacity).
    whiteBorder8: Color(0x14FFFFFF),
    whiteGlow20: Color(0x33FFFFFF),
    cyanBorder20: Color(0x3300E3FD),
    blackScrim50: Color(0x801A1A1A),
  );

  static const AppPalette light = AppPalette(
    accent: Color(0xFF4C6700),
    accentDim: Color(0xFF557300),
    accentBright: Color(0xFFC0FF00),
    accentDeep: Color(0xFF384E00),
    onAccent: Color(0xFFFFFFFF),
    homeHeroCard: Color(0xFFECEEF1),
    cyan: Color(0xFF0E7490),
    cyanDeep: Color(0xFF155E75),
    mint: Color(0xFF047857),
    success: Color(0xFF15803D),
    violet: Color(0xFF5B45D6),
    violetSoft: Color(0xFF4F46B8),
    pink: Color(0xFFECEDEF),
    coral: Color(0xFFC24E2F),
    orange: Color(0xFFC2410C),
    amber: Color(0xFFB45309),
    amberDeep: Color(0xFF9A3412),
    yellow: Color(0xFFA16207),
    danger: Color(0xFFBA1A1A),
    textPrimary: Color(0xFF1A1C1C),
    textMuted: Color(0xFF5E5E5E),
    textSoft: Color(0xFF646464),
    textGray: Color(0xFF6B6B6B),
    textFaint: Color(0xFF9E9E9E),
    textDim: Color(0xFFC6C6C6),
    fg: Color(0xFF1A1C1C),
    fg70: Color(0xFF4A4A4A),
    fg60: Color(0xFF5E5E5E),
    fg54: Color(0xFF6B6B6B),
    fg38: Color(0xFF9E9E9E),
    fg24: Color(0x33000000),
    fg12: Color(0x14000000),
    fg10: Color(0x1A000000),
    scaffold: Color(0xFFECEDEF),
    surfaceCard: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFFF4F5F7),
    surfaceSlate: Color(0xFFE3E6EA),
    surfaceMuted: Color(0xFFEDF0F3),
    surfacePanel: Color(0xFFFFFFFF),
    surfaceDeep: Color(0xFFEDF0F3),
    ink: Color(0xFFF9F9F9),
    inkCard: Color(0xFFFFFFFF),
    inkWarm: Color(0xFFFFFFFF),
    inkElevated: Color(0xFFE9EBEE),
    inkSoft: Color(0xFFE3E6EA),
    inkDeep: Color(0xFFFFFFFF),
    actionTileActive: Color(0xFF1A1C1C),
    onActionTileActive: Color(0xFFFFFFFF),
    actionTile: Color(0xFFE6E6E6),
    onActionTile: Color(0xFF1A1C1C),
    limeCream: Color(0xFF4C6700),
    limeSoft: Color(0xFF557300),
    limeOlive: Color(0xFF4D7C0F),
    limeShadow: Color(0xFF354900),
    limeInk: Color(0xFFEAF4CF),
    limeInkDim: Color(0xFFEEF6DA),
    limeInkDeep: Color(0xFFEAF4CF),
    scoreAmber: Color(0xFFB45309),
    scoreCoral: Color(0xFFC2410C),
    statusGreen: Color(0xFF15803D),
    statusOrange: Color(0xFFB45309),
    tealSoft: Color(0xFF0F766E),
    categoryTeal: Color(0xFF0F766E),
    categoryBlue: Color(0xFF1D4ED8),
    categoryPurple: Color(0xFF6D28D9),
    categoryBrown: Color(0xFF92400E),
    categoryBurntOrange: Color(0xFFC2410C),
    gold: Color(0xFFCA8A04),
    periwinkle: Color(0xFF4F6BD8),
    white: Color(0xFF1A1C1C),
    grayBright: Color(0xFF3F3F3F),
    grayLight: Color(0xFF4A4A4A),
    grayIos: Color(0xFF6D6D72),
    graySlate: Color(0xFF6B7280),
    graySlateDeep: Color(0xFF9CA3AF),
    gray55: Color(0xFF8E8E8E),
    gray3A: Color(0xFFD3D7DC),
    gray33: Color(0xFFDDE0E4),
    gray2A: Color(0xFFE4E6EA),
    grayWarm: Color(0xFF8A8686),
    dark0B0D10: Color(0xFFECEDEF),
    dark0D1117: Color(0xFFFFFFFF),
    dark0F0F1A: Color(0xFFECEDEF),
    dark111111: Color(0xFFFFFFFF),
    dark121212: Color(0xFFFFFFFF),
    dark151718: Color(0xFFFFFFFF),
    dark181818: Color(0xFFFFFFFF),
    dark1A1919: Color(0xFFFFFFFF),
    dark1A1D22: Color(0xFFECEDEF),
    dark1A2535: Color(0xFFE7F0FA),
    dark1E1E1E: Color(0xFFDDE0E4),
    dark1E1E2E: Color(0xFFF4F5F7),
    dark1E2A2A: Color(0xFFE6F0F0),
    dark1F2026: Color(0xFFE9EBEE),
    dark222528: Color(0xFFE9EBEE),
    dark2A2D32: Color(0xFFDDE0E4),
    dark2A2D33: Color(0xFFEDF0F3),
    dark2B2D31: Color(0xFFE4E6EA),
    dark2C2C2C: Color(0xFFE3E6EA),
    whiteBorder8: Color(0x14000000),
    whiteGlow20: Color(0x33000000),
    cyanBorder20: Color(0x330E7490),
    blackScrim50: Color(0x801A1A1A),
  );
}

/// Live token lookup. `AppColors.x` reads from the active [palette], which
/// the app root sets from the persisted theme mode BEFORE building the tree
/// (and forces a full rebuild on change). Defaults to dark, so tests and any
/// pre-theme code see the classic palette.
abstract final class AppColors {
  static AppPalette palette = AppPalette.dark;

  // Brand limes.
  static Color get accent => palette.accent;
  static Color get accentDim => palette.accentDim;
  static Color get accentBright => palette.accentBright;
  static Color get accentDeep => palette.accentDeep;
  static Color get onAccent => palette.onAccent;
  static Color get homeHeroCard => palette.homeHeroCard;
  // Secondary accents (light values darkened for white surfaces).
  static Color get cyan => palette.cyan;
  static Color get cyanDeep => palette.cyanDeep;
  static Color get mint => palette.mint;
  static Color get success => palette.success;
  static Color get violet => palette.violet;
  static Color get violetSoft => palette.violetSoft;
  static Color get pink => palette.pink;
  static Color get coral => palette.coral;
  static Color get orange => palette.orange;
  static Color get amber => palette.amber;
  static Color get amberDeep => palette.amberDeep;
  static Color get yellow => palette.yellow;
  static Color get danger => palette.danger;
  // Text.
  static Color get textPrimary => palette.textPrimary;
  static Color get textMuted => palette.textMuted;
  static Color get textSoft => palette.textSoft;
  static Color get textGray => palette.textGray;
  static Color get textFaint => palette.textFaint;
  static Color get textDim => palette.textDim;
  // Foreground scale — replaces direct Colors.white* uses so light mode
  // can invert them (dark: white opacities, light: ink grays).
  static Color get fg => palette.fg;
  static Color get fg70 => palette.fg70;
  static Color get fg60 => palette.fg60;
  static Color get fg54 => palette.fg54;
  static Color get fg38 => palette.fg38;
  static Color get fg24 => palette.fg24;
  static Color get fg12 => palette.fg12;
  static Color get fg10 => palette.fg10;
  // Surfaces — blue-tinted slate family (home, community, analytics).
  static Color get scaffold => palette.scaffold;
  static Color get surfaceCard => palette.surfaceCard;
  static Color get surfaceDark => palette.surfaceDark;
  static Color get surfaceSlate => palette.surfaceSlate;
  static Color get surfaceMuted => palette.surfaceMuted;
  static Color get surfacePanel => palette.surfacePanel;
  static Color get surfaceDeep => palette.surfaceDeep;
  // Surfaces — neutral obsidian family (add-task, editors, sheets).
  static Color get ink => palette.ink;
  static Color get inkCard => palette.inkCard;
  static Color get inkWarm => palette.inkWarm;
  static Color get inkElevated => palette.inkElevated;
  static Color get inkSoft => palette.inkSoft;
  static Color get inkDeep => palette.inkDeep;
  // Quick-action tiles (home). Light per mock: active tile is ink with
  // white glyph; idle tiles are gray with ink glyphs. Dark inverts.
  static Color get actionTileActive => palette.actionTileActive;
  static Color get onActionTileActive => palette.onActionTileActive;
  static Color get actionTile => palette.actionTile;
  static Color get onActionTile => palette.onActionTile;
  // One-off: lime tints (rebrand together with accent).
  static Color get limeCream => palette.limeCream;
  static Color get limeSoft => palette.limeSoft;
  static Color get limeOlive => palette.limeOlive;
  static Color get limeShadow => palette.limeShadow;
  static Color get limeInk => palette.limeInk;
  static Color get limeInkDim => palette.limeInkDim;
  static Color get limeInkDeep => palette.limeInkDeep;
  // One-off: score / status accents.
  static Color get scoreAmber => palette.scoreAmber;
  static Color get scoreCoral => palette.scoreCoral;
  static Color get statusGreen => palette.statusGreen;
  static Color get statusOrange => palette.statusOrange;
  static Color get tealSoft => palette.tealSoft;
  // One-off: goal-category colors.
  static Color get categoryTeal => palette.categoryTeal;
  static Color get categoryBlue => palette.categoryBlue;
  static Color get categoryPurple => palette.categoryPurple;
  static Color get categoryBrown => palette.categoryBrown;
  static Color get categoryBurntOrange => palette.categoryBurntOrange;
  // One-off: community accents.
  static Color get gold => palette.gold;
  static Color get periwinkle => palette.periwinkle;
  // One-off: whites & grays (light values invert intensity).
  static Color get white => palette.white;
  static Color get grayBright => palette.grayBright;
  static Color get grayLight => palette.grayLight;
  static Color get grayIos => palette.grayIos;
  static Color get graySlate => palette.graySlate;
  static Color get graySlateDeep => palette.graySlateDeep;
  static Color get gray55 => palette.gray55;
  static Color get gray3A => palette.gray3A;
  static Color get gray33 => palette.gray33;
  static Color get gray2A => palette.gray2A;
  static Color get grayWarm => palette.grayWarm;
  // One-off dark surfaces (named by their DARK hex; light maps to the
  // equivalent white/gray so the name stays a stable identifier).
  static Color get dark0B0D10 => palette.dark0B0D10;
  static Color get dark0D1117 => palette.dark0D1117;
  static Color get dark0F0F1A => palette.dark0F0F1A;
  static Color get dark111111 => palette.dark111111;
  static Color get dark121212 => palette.dark121212;
  static Color get dark151718 => palette.dark151718;
  static Color get dark181818 => palette.dark181818;
  static Color get dark1A1919 => palette.dark1A1919;
  static Color get dark1A1D22 => palette.dark1A1D22;
  static Color get dark1A2535 => palette.dark1A2535;
  static Color get dark1E1E1E => palette.dark1E1E1E;
  static Color get dark1E1E2E => palette.dark1E1E2E;
  static Color get dark1E2A2A => palette.dark1E2A2A;
  static Color get dark1F2026 => palette.dark1F2026;
  static Color get dark222528 => palette.dark222528;
  static Color get dark2A2D32 => palette.dark2A2D32;
  static Color get dark2A2D33 => palette.dark2A2D33;
  static Color get dark2B2D31 => palette.dark2B2D31;
  static Color get dark2C2C2C => palette.dark2C2C2C;
  // One-off alpha overlays (leading byte is opacity).
  static Color get whiteBorder8 => palette.whiteBorder8;
  static Color get whiteGlow20 => palette.whiteGlow20;
  static Color get cyanBorder20 => palette.cyanBorder20;
  static Color get blackScrim50 => palette.blackScrim50;
}
