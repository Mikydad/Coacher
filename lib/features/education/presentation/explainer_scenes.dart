import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/presentation/app_colors.dart';
import '../domain/page_explainers.dart';

/// The small illustration heading a [PageExplainer] sheet: round "blob"
/// characters acting out the idea. Painted rather than shipped as assets so
/// every color comes from [AppColors] and follows light/dark switching.
///
/// Drawn on a 280×150 design grid, scaled to the available width.
class ExplainerSceneView extends StatelessWidget {
  const ExplainerSceneView({super.key, required this.scene});

  final ExplainerScene scene;

  static const _designSize = Size(280, 150);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: _designSize.width / _designSize.height,
        child: CustomPaint(painter: _ScenePainter(scene, AppColors.isLight)),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, this.isLight);

  final ExplainerScene scene;

  /// Part of the repaint key: the palette is read at paint time.
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / ExplainerSceneView._designSize.width;
    canvas.save();
    canvas.scale(s);
    final k = _Kit(canvas);
    switch (scene) {
      case ExplainerScene.stake:
        _stake(k);
      case ExplainerScene.group:
        _group(k);
      case ExplainerScene.direction:
        _direction(k);
      case ExplainerScene.strictness:
        _strictness(k);
      case ExplainerScene.coach:
        _coach(k);
      case ExplainerScene.time:
        _time(k);
      case ExplainerScene.memory:
        _memory(k);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.scene != scene || old.isLight != isLight;

  // ─── Scenes ───────────────────────────────────────────────────────────────

  /// A nervous blob with a flag, a locked embarrassing photo, a ticking clock.
  void _stake(_Kit k) {
    final amber = k.soft(AppColors.amber);
    k.backdrop(AppColors.amber);
    k.dots(amber, const [Offset(30, 28), Offset(250, 122), Offset(146, 18)]);
    k.shadow(const Offset(92, 134), 40, amber);

    // Flag held up — the goal.
    k.line(const Offset(126, 104), const Offset(138, 50), k.ink(amber), 3);
    k.fill(
      Path()
        ..moveTo(138, 50)
        ..lineTo(166, 58)
        ..lineTo(136, 72)
        ..close(),
      k.soft(AppColors.coral),
    );
    k.blob(
      const Offset(92, 96),
      38,
      k.soft(AppColors.violet),
      _Mood.nervous,
      sweatLeft: true,
    );

    // The photo at stake, tilted like a print on a desk.
    k.canvas.save();
    k.canvas.translate(212, 82);
    k.canvas.rotate(8 * math.pi / 180);
    k.canvas.translate(-212, -82);
    final card = RRect.fromLTRBR(178, 42, 246, 122, const Radius.circular(6));
    k.canvas.drawRRect(card, Paint()..color = Colors.white);
    k.canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = amber,
    );
    final coral = k.soft(AppColors.coral);
    k.canvas.drawRRect(
      RRect.fromLTRBR(185, 49, 239, 99, const Radius.circular(3)),
      Paint()..color = coral.withValues(alpha: 0.22),
    );
    k.circle(const Offset(212, 78), 13, coral);
    k.stroke(
      Path()
        ..moveTo(199, 70)
        ..lineTo(203, 61)
        ..lineTo(207, 68)
        ..lineTo(212, 58)
        ..lineTo(216, 67)
        ..lineTo(221, 59)
        ..lineTo(224, 69),
      k.ink(coral),
      2,
    );
    k.circle(const Offset(207, 78), 1.8, k.ink(coral));
    k.circle(const Offset(217, 78), 1.8, k.ink(coral));
    k.canvas.drawOval(
      Rect.fromCenter(center: const Offset(212, 85), width: 6, height: 4.4),
      Paint()..color = k.ink(coral),
    );
    k.canvas.drawRRect(
      RRect.fromLTRBR(198, 104, 226, 108, const Radius.circular(2)),
      Paint()..color = amber.withValues(alpha: 0.25),
    );
    k.canvas.restore();

    // Padlock clamped on the photo's corner.
    k.stroke(
      Path()
        ..moveTo(234, 114)
        ..lineTo(234, 108)
        ..arcToPoint(const Offset(250, 108), radius: const Radius.circular(8))
        ..lineTo(250, 114),
      k.ink(amber),
      3.5,
    );
    k.canvas.drawRRect(
      RRect.fromLTRBR(230, 113, 254, 133, const Radius.circular(4)),
      Paint()..color = amber,
    );
    k.circle(const Offset(242, 122), 3, k.ink(amber));

    // Deadline clock with little tick lines.
    const c = Offset(246, 32);
    k.circle(c, 17, Colors.white);
    k.canvas.drawCircle(
      c,
      17,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = amber,
    );
    k.line(c, c + const Offset(0, -10), k.ink(amber), 2.5);
    k.line(c, c + const Offset(7, 4), k.ink(amber), 2.5);
    k.line(c + const Offset(-22, -14), c + const Offset(-26, -17), amber, 2);
    k.line(c + const Offset(-24, -4), c + const Offset(-29, -4), amber, 2);
  }

  /// Four friends with progress tags; one blushing at 0/3.
  void _group(_Kit k) {
    final mint = k.soft(AppColors.mint);
    k.backdrop(AppColors.mint);
    k.dots(mint, const [Offset(24, 24), Offset(262, 18), Offset(140, 12)]);
    k.canvas.drawRRect(
      RRect.fromLTRBR(10, 126, 270, 136, const Radius.circular(5)),
      Paint()..color = mint.withValues(alpha: 0.3),
    );

    final ok = AppColors.success;
    k.blob(const Offset(42, 104), 24, k.soft(AppColors.violet), _Mood.happy);
    k.tag(const Offset(42, 64), '2/3', ok);

    final coral = k.soft(AppColors.coral);
    k.line(const Offset(128, 86), const Offset(140, 72), coral, 7); // wave
    k.blob(const Offset(106, 100), 28, coral, _Mood.proud);
    k.tag(const Offset(106, 56), '3/3', ok);

    k.blob(const Offset(172, 104), 24, k.soft(AppColors.cyan), _Mood.happy);
    k.tag(const Offset(172, 64), '2/3', ok);

    k.blob(
      const Offset(236, 106),
      22,
      k.soft(AppColors.amber),
      _Mood.sheepish,
      sweatLeft: false,
    );
    k.tag(const Offset(236, 68), '0/3', AppColors.danger);
  }

  /// A blob on a winding path up to a star, with month/quarter flags.
  void _direction(_Kit k) {
    final accent = k.soft(AppColors.accent);
    k.backdrop(AppColors.accent);
    k.dots(accent, const [Offset(28, 22), Offset(120, 16), Offset(262, 110)]);

    // Rolling hills.
    k.canvas.drawOval(
      const Rect.fromLTRB(-40, 108, 170, 200),
      Paint()..color = accent.withValues(alpha: 0.22),
    );
    k.canvas.drawOval(
      const Rect.fromLTRB(110, 96, 330, 210),
      Paint()..color = accent.withValues(alpha: 0.34),
    );

    // The dashed trail toward the star.
    final trail = Path()
      ..moveTo(92, 128)
      ..cubicTo(150, 126, 120, 88, 170, 80)
      ..cubicTo(214, 72, 190, 48, 222, 40);
    k.dashed(trail, k.ink(accent).withValues(alpha: 0.55), 2.2);

    k.flag(const Offset(140, 101), k.soft(AppColors.cyan));
    k.flag(const Offset(196, 66), k.soft(AppColors.violet));

    k.star(const Offset(232, 32), 14, k.soft(AppColors.amber));
    final amber = k.soft(AppColors.amber);
    k.line(const Offset(252, 18), const Offset(258, 12), amber, 2);
    k.line(const Offset(254, 32), const Offset(262, 32), amber, 2);
    k.line(const Offset(212, 16), const Offset(207, 11), amber, 2);

    k.shadow(const Offset(70, 136), 28, accent);
    k.blob(
      const Offset(70, 110),
      27,
      k.soft(AppColors.mint),
      _Mood.determined,
      lookUp: true,
    );
  }

  /// Three blobs on a strictness slider: relaxed → focused → headband.
  void _strictness(_Kit k) {
    final violet = k.soft(AppColors.violet);
    k.backdrop(AppColors.violet);
    k.dots(violet, const [Offset(22, 20), Offset(260, 16), Offset(140, 14)]);

    final mint = k.soft(AppColors.mint);
    final amber = k.soft(AppColors.amber);
    final coral = k.soft(AppColors.coral);

    // Slider: three tinted segments, knob on the strictest.
    for (final (a, b, col) in [
      (40.0, 100.0, mint),
      (100.0, 180.0, amber),
      (180.0, 240.0, coral),
    ]) {
      k.line(Offset(a, 132), Offset(b, 132), col.withValues(alpha: 0.5), 8);
    }
    for (final x in [60.0, 140.0, 220.0]) {
      k.circle(Offset(x, 132), 4, Colors.white);
    }
    k.circle(const Offset(220, 132), 9, Colors.white);
    k.circle(const Offset(220, 132), 5.5, coral);

    k.blob(const Offset(60, 98), 21, mint, _Mood.calm);
    k.blob(const Offset(140, 94), 25, amber, _Mood.determined);
    k.blob(const Offset(220, 90), 29, coral, _Mood.determined);
    // Extreme wears a headband.
    final band = k.ink(coral);
    k.canvas.drawArc(
      Rect.fromCircle(center: const Offset(220, 90), radius: 27),
      math.pi * 1.12,
      math.pi * 0.76,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = band,
    );
    k.line(const Offset(244, 76), const Offset(256, 70), band, 3.5);
    k.line(const Offset(244, 78), const Offset(254, 82), band, 3.5);
  }

  /// A blob glancing up at a big clock over a day ribbon of logged blocks.
  void _time(_Kit k) {
    final orange = k.soft(AppColors.orange);
    k.backdrop(AppColors.orange);
    k.dots(orange, const [Offset(26, 22), Offset(140, 14), Offset(264, 20)]);

    // The day ribbon: logged blocks with honest gaps between them.
    k.canvas.drawRRect(
      RRect.fromLTRBR(118, 112, 266, 128, const Radius.circular(8)),
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
    for (final (a, b, col) in [
      (122.0, 162.0, k.soft(AppColors.violet)),
      (170.0, 188.0, k.soft(AppColors.coral)),
      (204.0, 262.0, k.soft(AppColors.mint)),
    ]) {
      k.canvas.drawRRect(
        RRect.fromLTRBR(a, 115, b, 125, const Radius.circular(5)),
        Paint()..color = col,
      );
    }

    // Big clock.
    const c = Offset(196, 60);
    k.circle(c, 32, Colors.white);
    k.canvas.drawCircle(
      c,
      32,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = orange,
    );
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final dir = Offset(math.cos(a), math.sin(a));
      k.line(c + dir * 25, c + dir * 28, orange.withValues(alpha: 0.7), 2);
    }
    k.line(c, c + const Offset(0, -18), k.ink(orange), 3);
    k.line(c, c + const Offset(13, 6), k.ink(orange), 3);
    k.circle(c, 3, k.ink(orange));

    k.shadow(const Offset(66, 136), 34, orange);
    k.blob(
      const Offset(66, 102),
      34,
      k.soft(AppColors.cyan),
      _Mood.happy,
      lookUp: true,
    );
  }

  /// A calm blob with a thought cloud holding a heart and a phone.
  void _memory(_Kit k) {
    final violet = k.soft(AppColors.violet);
    k.backdrop(AppColors.violet);
    k.dots(violet, const [Offset(24, 24), Offset(262, 128), Offset(120, 16)]);

    // Thought trail rising from the head.
    k.circle(const Offset(118, 70), 4, Colors.white);
    k.circle(const Offset(132, 58), 6, Colors.white);
    // The cloud.
    for (final (o, r) in [
      (const Offset(172, 56), 22.0),
      (const Offset(202, 40), 26.0),
      (const Offset(234, 52), 23.0),
      (const Offset(206, 68), 22.0),
      (const Offset(184, 70), 16.0),
    ]) {
      k.circle(o, r, Colors.white);
    }
    // A heart and a phone: "calling mom" remembered.
    final coral = k.soft(AppColors.coral);
    k.fill(
      Path()
        ..moveTo(186, 62)
        ..cubicTo(166, 48, 176, 32, 186, 42)
        ..cubicTo(196, 32, 206, 48, 186, 62)
        ..close(),
      coral,
    );
    final cyan = k.soft(AppColors.cyan);
    k.canvas.drawRRect(
      RRect.fromLTRBR(212, 36, 232, 68, const Radius.circular(5)),
      Paint()..color = cyan,
    );
    k.canvas.drawRRect(
      RRect.fromLTRBR(215, 41, 229, 60, const Radius.circular(2)),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    k.circle(const Offset(222, 64), 1.8, Colors.white);

    k.shadow(const Offset(78, 136), 36, violet);
    k.blob(const Offset(78, 102), 36, k.soft(AppColors.mint), _Mood.calm);
  }

  /// A blob with a speech bubble and a ticked "done" chip.
  void _coach(_Kit k) {
    final cyan = k.soft(AppColors.cyan);
    k.backdrop(AppColors.cyan);
    k.dots(cyan, const [Offset(24, 26), Offset(262, 130), Offset(120, 16)]);
    k.shadow(const Offset(86, 136), 38, cyan);
    k.blob(const Offset(86, 100), 36, cyan, _Mood.happy);

    // Speech bubble with a tail toward the blob.
    final bubble = Path()
      ..addRRect(RRect.fromLTRBR(138, 22, 262, 76, const Radius.circular(14)))
      ..moveTo(150, 70)
      ..lineTo(130, 88)
      ..lineTo(166, 74)
      ..close();
    k.fill(bubble, Colors.white);
    final inkC = k.ink(cyan).withValues(alpha: 0.35);
    k.line(const Offset(154, 40), const Offset(240, 40), inkC, 6);
    k.line(const Offset(154, 56), const Offset(214, 56), inkC, 6);

    // "Done" chip: the plan changed.
    k.canvas.drawRRect(
      RRect.fromLTRBR(158, 94, 256, 120, const Radius.circular(13)),
      Paint()..color = Colors.white,
    );
    k.circle(const Offset(172, 107), 8, AppColors.success);
    k.stroke(
      Path()
        ..moveTo(168, 107)
        ..lineTo(171, 110)
        ..lineTo(176, 104),
      Colors.white,
      2,
    );
    k.line(const Offset(188, 107), const Offset(240, 107), inkC, 5);

    k.star(const Offset(126, 34), 8, k.soft(AppColors.amber));
  }
}

enum _Mood { happy, nervous, proud, sheepish, calm, determined }

/// Drawing helpers on the 280×150 grid.
class _Kit {
  _Kit(this.canvas);

  final Canvas canvas;

  /// Light palette hues are deep (tuned for text contrast); lift them so
  /// the characters read as soft and friendly.
  Color soft(Color c) =>
      AppColors.isLight ? Color.lerp(c, Colors.white, 0.22)! : c;

  /// Same-hue dark for eyes, mouths and outlines.
  Color ink(Color c) => HSLColor.fromColor(c).withLightness(0.16).toColor();

  void backdrop(Color tint) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 280, 150),
      Paint()
        ..color = Color.lerp(
          AppColors.surfacePanel,
          tint,
          AppColors.isLight ? 0.12 : 0.18,
        )!,
    );
  }

  void dots(Color c, List<Offset> at) {
    for (final (i, o) in at.indexed) {
      circle(o, 2.5 + i % 2 * 1.5, c.withValues(alpha: 0.45));
    }
  }

  void shadow(Offset center, double halfWidth, Color c) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: halfWidth * 2, height: 12),
      Paint()..color = c.withValues(alpha: 0.28),
    );
  }

  void circle(Offset c, double r, Color color) =>
      canvas.drawCircle(c, r, Paint()..color = color);

  void fill(Path p, Color c) => canvas.drawPath(p, Paint()..color = c);

  void stroke(Path p, Color c, double w) => canvas.drawPath(
    p,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c,
  );

  void line(Offset a, Offset b, Color c, double w) => canvas.drawLine(
    a,
    b,
    Paint()
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = c,
  );

  void dashed(Path p, Color c, double w) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = c;
    for (final metric in p.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  void star(Offset c, double r, Color color) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// A little pennant planted at [base].
  void flag(Offset base, Color color) {
    line(base, base + const Offset(0, -22), ink(color), 2);
    fill(
      Path()
        ..moveTo(base.dx, base.dy - 22)
        ..lineTo(base.dx + 14, base.dy - 18)
        ..lineTo(base.dx, base.dy - 13)
        ..close(),
      color,
    );
  }

  /// A white pill with a short label (progress tags above the group).
  void tag(Offset center, String text, Color textColor) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: tp.width + 16, height: 18),
        const Radius.circular(9),
      ),
      Paint()..color = Colors.white,
    );
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  /// The house character: a round body with a face that carries the mood.
  void blob(
    Offset o,
    double r,
    Color body,
    _Mood mood, {
    bool? sweatLeft,
    bool lookUp = false,
  }) {
    final dark = ink(body);
    circle(o, r, body);
    // Soft top-left sheen.
    canvas.drawOval(
      Rect.fromCenter(
        center: o + Offset(-r * 0.34, -r * 0.56),
        width: r * 0.5,
        height: r * 0.26,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );

    final eyeY = lookUp ? -r * 0.16 : -r * 0.06;
    final eyeR = r * 0.13;
    for (final side in const [-1.0, 1.0]) {
      final eye = o + Offset(side * r * 0.3, eyeY);
      if (mood == _Mood.calm) {
        // Content, eyes closed.
        stroke(
          Path()
            ..moveTo(eye.dx - eyeR, eye.dy)
            ..quadraticBezierTo(eye.dx, eye.dy + eyeR, eye.dx + eyeR, eye.dy),
          dark,
          r * 0.07,
        );
      } else {
        circle(eye, eyeR, dark);
        final glint = mood == _Mood.sheepish
            ? Offset(eyeR * 0.3, eyeR * 0.35)
            : lookUp
            ? Offset(eyeR * 0.35, -eyeR * 0.45)
            : Offset(eyeR * 0.35, -eyeR * 0.35);
        circle(eye + glint, eyeR * 0.36, Colors.white);
      }
      // Blush.
      canvas.drawOval(
        Rect.fromCenter(
          center: o + Offset(side * r * 0.54, r * 0.2),
          width: r * 0.32,
          height: r * 0.18,
        ),
        Paint()
          ..color = AppColors.coral.withValues(
            alpha: mood == _Mood.sheepish ? 0.7 : 0.4,
          ),
      );
    }

    final m = o + Offset(0, r * 0.3);
    final w = r * 0.2;
    final mouth = Path();
    switch (mood) {
      case _Mood.happy:
      case _Mood.calm:
        mouth
          ..moveTo(m.dx - w, m.dy - w * 0.3)
          ..quadraticBezierTo(m.dx, m.dy + w * 0.7, m.dx + w, m.dy - w * 0.3);
      case _Mood.proud:
        fill(
          Path()
            ..moveTo(m.dx - w * 1.2, m.dy - w * 0.4)
            ..quadraticBezierTo(
              m.dx,
              m.dy + w * 1.3,
              m.dx + w * 1.2,
              m.dy - w * 0.4,
            )
            ..close(),
          dark,
        );
      case _Mood.nervous:
        mouth
          ..moveTo(m.dx - w, m.dy)
          ..quadraticBezierTo(m.dx - w / 2, m.dy - w * 0.4, m.dx, m.dy)
          ..quadraticBezierTo(m.dx + w / 2, m.dy + w * 0.4, m.dx + w, m.dy);
      case _Mood.sheepish:
        mouth
          ..moveTo(m.dx - w * 0.7, m.dy + w * 0.3)
          ..quadraticBezierTo(
            m.dx,
            m.dy - w * 0.3,
            m.dx + w * 0.7,
            m.dy + w * 0.3,
          );
      case _Mood.determined:
        mouth
          ..moveTo(m.dx - w * 0.8, m.dy)
          ..quadraticBezierTo(
            m.dx,
            m.dy + w * 0.35,
            m.dx + w * 0.8,
            m.dy - w * 0.1,
          );
    }
    stroke(mouth, dark, math.max(1.6, r * 0.07));

    if (sweatLeft != null) {
      final d = o + Offset((sweatLeft ? -1 : 1) * r * 0.9, -r * 0.55);
      fill(
        Path()
          ..moveTo(d.dx, d.dy - r * 0.2)
          ..quadraticBezierTo(d.dx + r * 0.14, d.dy, d.dx, d.dy + r * 0.07)
          ..quadraticBezierTo(d.dx - r * 0.14, d.dy, d.dx, d.dy - r * 0.2),
        AppColors.cyan.withValues(alpha: 0.75),
      );
    }
  }
}
