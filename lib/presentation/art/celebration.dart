import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art_kit.dart';

/// Kurze, freundliche Erfolgsanimation (ca. 3,2 s): Funkelring, Konfetti, Sternenregen.
/// Verblasst von selbst; kein Dauerflimmern. [et] = Sekunden seit Ende des Timers.
class CelebrationPainter extends CustomPainter {
  CelebrationPainter({required this.et});
  final double et;

  static const _colors = [
    Color(0xFFFF7A59),
    Color(0xFFFFC83D),
    Color(0xFF2FC4A8),
    Color(0xFF6EC1F5),
    Color(0xFFB57BE0),
    Color(0xFFFF7BA5),
  ];
  static const duration = 3.4;

  @override
  void paint(Canvas canvas, Size size) {
    if (et < 0 || et > duration) return;
    final fade = 1 - smoothstep(2.4, duration, et);
    final c = size.center(Offset(0, -size.height * 0.05));
    final s = size.shortestSide;
    // 1) leuchtender Ring, der sich einmal ausbreitet
    final ring = smoothstep(0, 0.9, et);
    canvas.drawCircle(
      c,
      s * (0.15 + ring * 0.42),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03 * (1 - ring * 0.7)
        ..color = const Color(0xFFFFE27A).withValues(alpha: (1 - ring) * 0.85),
    );
    // 2) Konfetti-Bänder: Wurf nach oben, dann Schwerkraft und leichtes Schaukeln
    final rnd = Rng(17);
    for (var i = 0; i < 72; i++) {
      final ang = -math.pi / 2 + rnd.range(-1.15, 1.15);
      final speed = rnd.range(0.55, 1.15) * s;
      final delay = rnd.range(0, 0.25);
      final k = et - delay;
      if (k <= 0) continue;
      final vx = math.cos(ang) * speed;
      final vy = math.sin(ang) * speed;
      final x = c.dx + vx * k * 0.75 + math.sin(k * 3 + i) * s * 0.02;
      final y = c.dy + vy * k * 0.75 + 0.5 * s * 1.15 * k * k;
      final col = _colors[i % _colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(k * rnd.range(2, 6) + i);
      final w = s * 0.036, h = s * 0.018;
      final flip = math.cos(k * 8 + i); // Band kippt: wirkt dreidimensional
      canvas.scale(1, 0.35 + 0.65 * flip.abs());
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, w * 0.45, Paint()..color = col);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            Radius.circular(h * 0.4),
          ),
          Paint()..color = col,
        );
      }
      canvas.restore();
    }
    // 3) ein paar große Sterne, die sanft nach oben steigen und ausblenden
    for (var i = 0; i < 5; i++) {
      final k = et - 0.1 * i;
      if (k <= 0) continue;
      final a = -math.pi / 2 + (i - 2) * 0.55;
      final r = s * (0.18 + 0.2 * smoothstep(0, 1.6, k));
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r * 0.8);
      final size2 =
          s * 0.035 * (1 - 0.2 * i / 5) * (0.6 + 0.4 * math.sin(k * 6 + i));
      _star(
        canvas,
        p,
        size2.abs(),
        const Color(0xFFFFE27A).withValues(alpha: fade),
      );
      glow(canvas, p, size2 * 3, const Color(0xFFFFE27A), 0.3 * fade);
    }
  }

  void _star(Canvas c, Offset p, double r, Color col) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = p + Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), Paint()..color = col);
  }

  @override
  bool shouldRepaint(CelebrationPainter old) => old.et != et;
}
