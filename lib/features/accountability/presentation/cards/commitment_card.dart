import 'package:flutter/material.dart';

/// Public Commitment Cards — the shareable pledge / success / failure images
/// (tasks/prd-public-commitment-cards.md, FR-14/FR-18/FR-19/FR-20).
///
/// The card is an EXPORT surface, not app chrome: it lands on Instagram and
/// WhatsApp feeds, so it deliberately ignores the app's light/dark theme and
/// paints one fixed look per state (PRD §6 — the decision-logged exemption
/// from the AppColors rule). Backgrounds are Miko's text-free plates
/// (assets/images/stake_cards/); every character of text is layered here so
/// it stays razor sharp and dynamic.
///
/// Rendered at a fixed logical size and captured via RepaintBoundary at
/// pixelRatio 3 → 1080×1920 (story) / 1080×1080 (square) PNG.

/// Bundled with the app (pubspec `CardSans`) so exports render identically
/// on every device — never the platform font (FR-20).
const kCardFontFamily = 'CardSans';

enum CommitmentCardState { pledge, success, failure }

enum CommitmentCardAspect { story, square }

/// Everything a card needs, derived on demand from challenge data (FR-21 —
/// cards are never stored).
class CommitmentCardData {
  const CommitmentCardData({
    required this.state,
    required this.goalTitle,
    required this.deadline,
    this.displayName = '',
    this.note = '',
    this.completedOn,
    this.unitsPassed,
    this.unitsRequired,
    this.unitNoun = 'days',
    this.recommitDate,
    this.surrendered = false,
  });

  final CommitmentCardState state;
  final String goalTitle;

  /// The committed deadline (pledge/failure show it; success shows
  /// [completedOn] when available).
  final DateTime deadline;
  final String displayName;

  /// The 280-char pledge "why" — the motivation note (FR-8).
  final String note;
  final DateTime? completedOn;
  final int? unitsPassed;
  final int? unitsRequired;
  final String unitNoun;

  /// Failure card only: turns the box line into a recommitment (FR-14).
  final DateTime? recommitDate;

  /// Failure copy variant for a surrendered challenge (FR-16).
  final bool surrendered;
}

/// Swap point for the plate art (FR-19): bundled assets today, cached remote
/// plates later — callers never reference paths directly.
String plateAssetFor(CommitmentCardState state) => switch (state) {
  CommitmentCardState.pledge => 'assets/images/stake_cards/plate_pledge.jpg',
  CommitmentCardState.success => 'assets/images/stake_cards/plate_success.jpg',
  CommitmentCardState.failure => 'assets/images/stake_cards/plate_failure.jpg',
};

/// Native aspect of each plate (w/h) — the art has framed borders and
/// anchored emblems, so it is never crop-filled; the card renders at this
/// ratio and floats on the export canvas.
double plateAspectFor(CommitmentCardState state) => switch (state) {
  CommitmentCardState.pledge => 1086 / 1448, // 3:4
  _ => 1023 / 1537, // 2:3
};

// ─── Fixed card palette (theme-exempt by design, PRD §6) ─────────────────────

class _Ink {
  // Pledge (parchment plate).
  static const parchmentDark = Color(0xFF221A10);
  static const parchmentBody = Color(0xFF55432A);
  static const goldDeep = Color(0xFF8A6A2E);
  static const gold = Color(0xFFA9822F);
  static const goldBoxText = Color(0xFF6B5320);
  // Success (dark green/gold plate).
  static const successGoldHi = Color(0xFFF6E7B0);
  static const successGoldLo = Color(0xFFD9A937);
  static const successGreen = Color(0xFF8FCB7A);
  static const successBody = Color(0xFFCFE6C4);
  static const successFooter = Color(0xFFD9C27A);
  static const white = Color(0xFFF4F4F2);
  // Failure (black/red plate).
  static const silverHi = Color(0xFFF2F2F2);
  static const silverLo = Color(0xFF9DA1A8);
  static const red = Color(0xFFE05B4F);
  static const redDim = Color(0xFFD9534A);
  static const redBox = Color(0xFFE08A80);
}

const _months = [
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER',
];

String _date(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

/// The card: a state plate at native aspect, text layered in the art's
/// reserved zones, centered on a state-tinted export canvas.
class CommitmentCard extends StatelessWidget {
  const CommitmentCard({super.key, required this.data, required this.aspect});

  final CommitmentCardData data;
  final CommitmentCardAspect aspect;

  /// Logical canvas sizes; capture at pixelRatio 3 → 1080×1920 / 1080×1080.
  static const storySize = Size(360, 640);
  static const squareSize = Size(360, 360);

  Size get canvasSize =>
      aspect == CommitmentCardAspect.story ? storySize : squareSize;

  @override
  Widget build(BuildContext context) {
    final (bgCenter, bgEdge) = switch (data.state) {
      CommitmentCardState.pledge => (
        const Color(0xFF2A2118),
        const Color(0xFF141210),
      ),
      CommitmentCardState.success => (
        const Color(0xFF16241A),
        const Color(0xFF0C120D),
      ),
      CommitmentCardState.failure => (
        const Color(0xFF241214),
        const Color(0xFF120A0B),
      ),
    };
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: canvasSize.width,
        height: canvasSize.height,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3),
            radius: 1.2,
            colors: [bgCenter, bgEdge],
          ),
        ),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ratio = plateAspectFor(data.state);
              final maxW = constraints.maxWidth * 0.90;
              final maxH = constraints.maxHeight * 0.92;
              var w = maxW;
              var h = w / ratio;
              if (h > maxH) {
                h = maxH;
                w = h * ratio;
              }
              return SizedBox(width: w, height: h, child: _plate(w, h));
            },
          ),
        ),
      ),
    );
  }

  Widget _plate(double w, double h) {
    final overlays = switch (data.state) {
      CommitmentCardState.pledge => _pledgeOverlays(w, h),
      CommitmentCardState.success => _successOverlays(w, h),
      CommitmentCardState.failure => _failureOverlays(w, h),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(plateAssetFor(data.state), fit: BoxFit.fill),
          ...overlays,
        ],
      ),
    );
  }

  // Zone helper: a fractional band of the plate, horizontally padded.
  Widget _zone(
    double w,
    double h, {
    required double top,
    required double height,
    double hPad = 0.09,
    required Widget child,
  }) {
    return Positioned(
      top: h * top,
      height: h * height,
      left: w * hPad,
      right: w * hPad,
      child: child,
    );
  }

  Widget _micro(String text, Color color, {double size = 10}) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontFamily: kCardFontFamily,
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
        ),
      ),
    ),
  );

  Widget _fitted(
    String text, {
    required Color color,
    double size = 26,
    FontWeight weight = FontWeight.w800,
    double letterSpacing = 0.5,
  }) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        style: TextStyle(
          fontFamily: kCardFontFamily,
          color: color,
          fontSize: size,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1.0,
        ),
      ),
    ),
  );

  Widget _body(
    String text,
    Color color, {
    int maxLines = 2,
    double size = 12.5,
  }) => Center(
    child: Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: kCardFontFamily,
        color: color,
        fontSize: size,
        height: 1.3,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  /// Metallic headline — gradient-masked heavy caps ("I DID IT." effect).
  Widget _metal(String text, Color hi, Color lo) => Center(
    child: ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [hi, lo],
      ).createShader(bounds),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: kCardFontFamily,
            // The mask paints the gradient over this white.
            color: Colors.white,
            fontSize: 44,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1.0,
          ),
        ),
      ),
    ),
  );

  // ─── Pledge (3:4 parchment) ────────────────────────────────────────────────

  List<Widget> _pledgeOverlays(double w, double h) {
    final ts = h / 432;
    final boxLine = data.displayName.isEmpty
        ? "I'M SHARING THIS. HOLD ME ACCOUNTABLE."
        : '${data.displayName.toUpperCase()} · HOLD ME ACCOUNTABLE.';
    return [
      _zone(
        w,
        h,
        top: 0.192,
        height: 0.036,
        child: _micro('PUBLIC COMMITMENT', _Ink.gold),
      ),
      _zone(
        w,
        h,
        top: 0.252,
        height: 0.085,
        child: _fitted(
          'I COMMIT.',
          color: _Ink.parchmentDark,
          size: 44,
          weight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
      if (data.note.isNotEmpty)
        _zone(
          w,
          h,
          top: 0.336,
          height: 0.062,
          hPad: 0.12,
          child: _body(data.note, _Ink.parchmentBody, size: 10.5 * ts),
        ),
      _zone(
        w,
        h,
        top: 0.447,
        height: 0.028,
        child: _micro('I WILL', _Ink.gold),
      ),
      _zone(
        w,
        h,
        top: 0.480,
        height: 0.052,
        child: _fitted(data.goalTitle.toUpperCase(), color: _Ink.parchmentDark),
      ),
      _zone(w, h, top: 0.540, height: 0.026, child: _micro('BY', _Ink.gold)),
      _zone(
        w,
        h,
        top: 0.570,
        height: 0.046,
        child: _fitted(_date(data.deadline), color: _Ink.goldDeep, size: 22),
      ),
      _zone(
        w,
        h,
        top: 0.641,
        height: 0.040,
        hPad: 0.23,
        child: _fitted(
          boxLine,
          color: _Ink.goldBoxText,
          size: 12,
          weight: FontWeight.w700,
        ),
      ),
    ];
  }

  // ─── Success (2:3 crown) ───────────────────────────────────────────────────

  List<Widget> _successOverlays(double w, double h) {
    final ts = h / 487;
    final date = data.completedOn ?? data.deadline;
    final stats = <String>[
      if (data.displayName.isNotEmpty) data.displayName.toUpperCase(),
      if (data.unitsPassed != null && data.unitsRequired != null)
        '${data.unitsPassed}/${data.unitsRequired} ${data.unitNoun.toUpperCase()}',
    ];
    return [
      _zone(
        w,
        h,
        top: 0.245,
        height: 0.088,
        child: _metal('I DID IT.', _Ink.successGoldHi, _Ink.successGoldLo),
      ),
      if (data.note.isNotEmpty)
        _zone(
          w,
          h,
          top: 0.398,
          height: 0.080,
          hPad: 0.12,
          child: _body(data.note, _Ink.successBody, size: 12.5 * ts),
        ),
      _zone(
        w,
        h,
        top: 0.508,
        height: 0.026,
        child: _micro('I SAID I WOULD', _Ink.successGreen),
      ),
      _zone(
        w,
        h,
        top: 0.538,
        height: 0.052,
        hPad: 0.12,
        child: _fitted(data.goalTitle.toUpperCase(), color: _Ink.white),
      ),
      _zone(
        w,
        h,
        top: 0.602,
        height: 0.042,
        child: _fitted('ON ${_date(date)}', color: _Ink.successGreen, size: 18),
      ),
      if (stats.isNotEmpty)
        _zone(
          w,
          h,
          top: 0.878,
          height: 0.036,
          child: _micro(
            '— ${stats.join(' · ')} —',
            _Ink.successFooter,
            size: 10.5,
          ),
        ),
    ];
  }

  // ─── Failure (2:3 cracked black) ───────────────────────────────────────────

  List<Widget> _failureOverlays(double w, double h) {
    final ts = h / 487;
    final passed = data.unitsPassed ?? 0;
    final required = data.unitsRequired ?? 0;
    final hasProgress = passed > 0 && required > 0;
    const missVerb = 'I SAID I WOULD';
    final boxParts = <String>[
      if (data.surrendered)
        'I GAVE UP THIS TIME — NOT FOREVER.'
      else
        'A SETBACK, NOT THE END.',
      if (data.recommitDate != null)
        'ROUND TWO: ${_date(data.recommitDate!)}'
      else if (data.displayName.isNotEmpty)
        '${data.displayName.toUpperCase()} KEEPS GOING.',
    ];
    return [
      _zone(
        w,
        h,
        top: 0.268,
        height: 0.088,
        child: _metal("I DIDN'T.", _Ink.silverHi, _Ink.silverLo),
      ),
      // Progress-led (FR-14): the stat is the hero when there is one;
      // zero progress degrades to honest recommit framing.
      if (hasProgress) ...[
        _zone(
          w,
          h,
          top: 0.392,
          height: 0.092,
          child: _metal('$passed / $required', _Ink.white, _Ink.silverLo),
        ),
        _zone(
          w,
          h,
          top: 0.492,
          height: 0.026,
          child: _micro('${data.unitNoun.toUpperCase()} DONE', _Ink.red),
        ),
      ] else
        _zone(
          w,
          h,
          top: 0.415,
          height: 0.055,
          child: _fitted("I DIDN'T START.", color: _Ink.silverLo, size: 20),
        ),
      _zone(w, h, top: 0.536, height: 0.026, child: _micro(missVerb, _Ink.red)),
      _zone(
        w,
        h,
        top: 0.566,
        height: 0.052,
        hPad: 0.12,
        child: _fitted(data.goalTitle.toUpperCase(), color: _Ink.silverHi),
      ),
      _zone(
        w,
        h,
        top: 0.628,
        height: 0.040,
        child: _fitted(
          'BY ${_date(data.deadline)}',
          color: _Ink.redDim,
          size: 17,
        ),
      ),
      _zone(
        w,
        h,
        top: 0.872,
        height: 0.062,
        hPad: 0.16,
        child: _body(boxParts.join('\n'), _Ink.redBox, size: 10.5 * ts),
      ),
    ];
  }
}
