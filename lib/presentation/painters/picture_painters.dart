import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/catalog.dart';

/// Bild-Timer: Ein Bild verändert sich mit der Zeit. Reine Darstellung –
/// bekommt nur den Restanteil [fraction] (1 → 0). Die Veränderung ist immer
/// auch an Form/Menge ablesbar, nie nur an der Farbe.
class PicturePainter extends CustomPainter {
  PicturePainter({
    required this.style,
    required this.fraction,
    required this.t,
    this.calm = false,
  });
  final TimerStyle style;
  final double fraction, t;
  final bool calm;

  Paint _f(Color c) => Paint()..color = c;
  Paint _s(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  double get _f01 => fraction.clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    canvas.scale(s / 100);
    switch (style) {
      case TimerStyle.iceCream:
        _ice(canvas);
      case TimerStyle.candle:
        _candle(canvas);
      case TimerStyle.plant:
        _plant(canvas);
      case TimerStyle.pizza:
        _pizza(canvas);
      case TimerStyle.puzzle:
        _puzzle(canvas);
      default:
        break;
    }
    canvas.restore();
  }

  // ---- Eis schmilzt: drei Kugeln, die oberste schmilzt zuerst ----
  void _ice(Canvas c) {
    final f = _f01;
    c.save();
    c.translate(7.5, 14);
    c.scale(0.85);
    final puddleW = 14 + (1 - f) * 34;
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(50, 93),
        width: puddleW * 2,
        height: 7,
      ),
      _f(const Color(0xFFF4A6C0)),
    );
    // Waffel
    final cone = Path()
      ..moveTo(33, 58)
      ..lineTo(67, 58)
      ..lineTo(50, 92)
      ..close();
    c.drawPath(cone, _f(const Color(0xFFE8B070)));
    c.save();
    c.clipPath(cone);
    for (var i = -3; i < 6; i++) {
      c.drawLine(
        Offset(30 + i * 7, 56),
        Offset(50 + i * 7, 96),
        _s(const Color(0xFFC98E4A), 1.2),
      );
      c.drawLine(
        Offset(70 - i * 7, 56),
        Offset(50 - i * 7, 96),
        _s(const Color(0xFFC98E4A), 1.2),
      );
    }
    c.restore();
    final cols = [
      const Color(0xFFF7B3C2),
      const Color(0xFFFFF0B8),
      const Color(0xFF9B6B43),
    ];
    final amount = [
      (f * 3).clamp(0.0, 1.0),
      ((f - 1 / 3) * 3).clamp(0.0, 1.0),
      ((f - 2 / 3) * 3).clamp(0.0, 1.0),
    ];
    var y = 52.0;
    for (var i = 0; i < 3; i++) {
      final a = amount[i];
      if (a <= 0.02) continue;
      final r = 15 * (0.55 + 0.45 * a);
      final cy = y - r * 0.6;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(50, cy),
          width: r * 2.3,
          height: r * 2 * (0.7 + 0.3 * a),
        ),
        _f(cols[i]),
      );
      // Glanzlicht
      c.drawCircle(
        Offset(44, cy - r * 0.35),
        r * 0.16,
        _f(Colors.white.withValues(alpha: 0.6)),
      );
      // Tropfen über den Waffelrand
      if (a < 1) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(36 + i * 6, cy, 4, 6 + (1 - a) * 14),
            const Radius.circular(2),
          ),
          _f(cols[i]),
        );
      }
      y -= r * 1.1;
    }
    if (f > 0.02) {
      final drop = calm ? 0.0 : (t * 0.8) % 1;
      c.drawOval(
        Rect.fromCenter(
          center: Offset(66, 60 + drop * 30),
          width: 3.5,
          height: 5,
        ),
        _f(cols[0].withValues(alpha: 1 - drop)),
      );
    }
    c.restore();
  }

  // ---- Kerze brennt ab ----
  void _candle(Canvas c) {
    final f = _f01;
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 90), width: 52, height: 9),
      _f(const Color(0xFFB8A9D9)),
    );
    final h = 8 + f * 62;
    final top = 86 - h;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(38, top, 24, h),
      const Radius.circular(3),
    );
    c.drawRRect(body, _f(const Color(0xFFFFF3D6)));
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(38, top, 6, h),
        const Radius.circular(3),
      ),
      _f(const Color(0xFFF1DDB0)),
    );
    // Wachstropfen
    if (f > 0.02) {
      for (final dx in [40.0, 55.0]) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(dx, top, 4, 6 + (1 - f) * 9 + (dx == 40 ? 3 : 0)),
            const Radius.circular(2),
          ),
          _f(const Color(0xFFFFF3D6)),
        );
      }
    }
    c.drawLine(
      Offset(50, top),
      Offset(50, top - 5),
      _s(const Color(0xFF3A3A4A), 1.6),
    );
    if (f > 0.02) {
      final fl = calm ? 0.0 : math.sin(t * 9) * 1.2;
      final flame = Path()
        ..moveTo(50, top - 5)
        ..quadraticBezierTo(41, top - 14, 50 + fl, top - 28)
        ..quadraticBezierTo(59, top - 14, 50, top - 5)
        ..close();
      c.drawCircle(Offset(50, top - 14), 13, _f(const Color(0x22FFC83D)));
      c.drawPath(flame, _f(const Color(0xFFFF9F43)));
      c.drawPath(
        Path()
          ..moveTo(50, top - 6)
          ..quadraticBezierTo(46, top - 12, 50 + fl * 0.5, top - 19)
          ..quadraticBezierTo(54, top - 12, 50, top - 6),
        _f(const Color(0xFFFFE680)),
      );
    } else {
      // Rauchfähnchen nach dem Löschen
      final w = calm ? 0.0 : math.sin(t * 3) * 3;
      final smoke = Path()
        ..moveTo(50, top - 5)
        ..quadraticBezierTo(46 + w, top - 14, 52, top - 22)
        ..quadraticBezierTo(56 - w, top - 30, 50, top - 38);
      c.drawPath(smoke, _s(const Color(0x66777799), 2));
    }
  }

  // ---- Blume wächst: Fortschritt = 1 - Rest ----
  void _plant(Canvas c) {
    final p = 1 - _f01;
    c.drawPath(
      Path()
        ..moveTo(32, 74)
        ..lineTo(68, 74)
        ..lineTo(63, 96)
        ..lineTo(37, 96)
        ..close(),
      _f(const Color(0xFFE08A4C)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(29, 70, 42, 8),
        const Radius.circular(3),
      ),
      _f(const Color(0xFFC96F32)),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 71), width: 36, height: 5),
      _f(const Color(0xFF6B4423)),
    );
    final sway = calm ? 0.0 : math.sin(t * 1.8) * 1.5;
    final stemH = 4 + p * 42;
    final topX = 50 + sway * p;
    final topY = 71 - stemH;
    c.drawPath(
      Path()
        ..moveTo(50, 71)
        ..quadraticBezierTo(50 + sway * p * 0.5, 71 - stemH * 0.5, topX, topY),
      _s(const Color(0xFF4FA860), 3.2),
    );
    // Blätter erscheinen nacheinander
    for (var i = 0; i < 4; i++) {
      final at = 0.12 + i * 0.16;
      if (p < at) continue;
      final k = ((p - at) / 0.12).clamp(0.0, 1.0);
      final side = i.isEven ? -1.0 : 1.0;
      final ly = 71 - stemH * (0.25 + i * 0.17);
      c.save();
      c.translate(50, ly);
      c.rotate(side * 0.7);
      c.drawOval(
        Rect.fromLTWH(side > 0 ? 0 : -14 * k, -3 * k, 14 * k, 6 * k),
        _f(const Color(0xFF6CC47A)),
      );
      c.restore();
    }
    // Knospe → Blüte
    if (p > 0.6) {
      final k = ((p - 0.6) / 0.4).clamp(0.0, 1.0);
      final r = 3 + 11 * k;
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + (calm ? 0 : t * 0.2);
        c.drawCircle(
          Offset(topX + math.cos(a) * r, topY + math.sin(a) * r),
          3 + 5 * k,
          _f(const Color(0xFFF4709B)),
        );
      }
      c.drawCircle(Offset(topX, topY), 2 + 5 * k, _f(const Color(0xFFFFD84D)));
    } else {
      c.drawOval(
        Rect.fromCenter(center: Offset(topX, topY - 2), width: 7, height: 10),
        _f(const Color(0xFF6CC47A)),
      );
    }
  }

  // ---- Pizza wird gegessen: Stücke verschwinden ----
  void _pizza(Canvas c) {
    const center = Offset(50, 52);
    const r = 40.0;
    c.drawCircle(center, r + 7, _f(const Color(0xFFF1EDF7)));
    c.drawCircle(center, r + 7, _s(const Color(0xFFD9D4E8), 1.5));
    const n = 8;
    final shown = _f01 * n; // z. B. 5.3 Stücke
    for (var i = 0; i < n; i++) {
      final vis = (shown - i).clamp(0.0, 1.0);
      if (vis <= 0) continue;
      final a0 = -math.pi / 2 + i * 2 * math.pi / n;
      final sweep = 2 * math.pi / n;
      final rr = r * (0.55 + 0.45 * vis); // angebissenes Stück wird kleiner
      final rect = Rect.fromCircle(center: center, radius: rr);
      c.drawArc(
        rect,
        a0 + 0.012,
        sweep - 0.024,
        true,
        _f(const Color(0xFFE8B070)),
      );
      c.drawArc(
        Rect.fromCircle(center: center, radius: rr * 0.88),
        a0 + 0.05,
        sweep - 0.1,
        true,
        _f(const Color(0xFFFFD66B)),
      );
      final mid = a0 + sweep / 2;
      c.drawCircle(
        center + Offset(math.cos(mid), math.sin(mid)) * rr * 0.55,
        3.6 * vis,
        _f(const Color(0xFFD9473E)),
      );
      c.drawCircle(
        center + Offset(math.cos(mid + 0.12), math.sin(mid + 0.12)) * rr * 0.82,
        2.2 * vis,
        _f(const Color(0xFF58B368)),
      );
    }
  }

  // ---- Bildpuzzle: verdeckte Kacheln verschwinden, Bild wird sichtbar ----
  void _puzzle(Canvas c) {
    const n = 4;
    const size = 84.0;
    const o = Offset(8, 8);
    final box = RRect.fromRectAndRadius(
      Rect.fromLTWH(o.dx, o.dy, size, size),
      const Radius.circular(6),
    );
    c.save();
    c.clipRRect(box);
    // Das verborgene Bild: Himmel, Sonne, Hügel, Haus
    c.drawRect(
      Rect.fromLTWH(o.dx, o.dy, size, size),
      _f(const Color(0xFF8FD3F4)),
    );
    c.drawCircle(const Offset(72, 26), 9, _f(const Color(0xFFFFD84D)));
    c.drawOval(
      Rect.fromCenter(center: const Offset(30, 92), width: 110, height: 52),
      _f(const Color(0xFF7CC857)),
    );
    c.drawOval(
      Rect.fromCenter(center: const Offset(80, 96), width: 70, height: 40),
      _f(const Color(0xFF9BDB6E)),
    );
    c.drawRect(
      const Rect.fromLTWH(34, 56, 24, 20),
      _f(const Color(0xFFFFF3D6)),
    );
    c.drawPath(
      Path()
        ..moveTo(31, 57)
        ..lineTo(46, 44)
        ..lineTo(61, 57)
        ..close(),
      _f(const Color(0xFFE5574B)),
    );
    c.drawRect(const Rect.fromLTWH(43, 64, 7, 12), _f(const Color(0xFF8A5A2B)));
    c.restore();
    // Verdeckende Kacheln in fester, gemischter Reihenfolge
    const order = [5, 10, 0, 15, 6, 9, 3, 12, 1, 14, 4, 11, 7, 8, 2, 13];
    final covered = (_f01 * n * n).ceil();
    const cell = size / n;
    for (var k = 0; k < n * n; k++) {
      // Kachel order[k] ist verdeckt, solange k < covered
      if (k >= covered) continue;
      final idx = order[k];
      final r = Rect.fromLTWH(
        o.dx + (idx % n) * cell,
        o.dy + (idx ~/ n) * cell,
        cell,
        cell,
      ).deflate(0.8);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      c.drawRRect(
        rr,
        _f(
          Color.lerp(
            const Color(0xFF7C6BE0),
            const Color(0xFFB57BE0),
            (idx % 3) / 3,
          )!,
        ),
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, r.center - Offset(tp.width / 2, tp.height / 2));
    }
    c.drawRRect(box, _s(Colors.white, 2.5));
  }

  @override
  bool shouldRepaint(PicturePainter o) =>
      o.fraction != fraction || o.t != t || o.style != style;
}
