import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/catalog.dart';

/// Stimmung/Animationszustand einer Figur.
enum Mood { idle, active, sleepy, happy }

/// Zeichnet alle Figuren als eigene Vektorgrafik im Einheitsquadrat [-1,1].
///
/// [t] = Animationszeit in Sekunden (nur Darstellung, keine Timerlogik).
/// [calm] = Ruhiger Modus: keine Bewegung, keine Funkeleffekte.
class CharacterPainter extends CustomPainter {
  CharacterPainter(
    this.spec, {
    this.t = 0,
    this.mood = Mood.idle,
    this.calm = false,
    this.shadow = true,
  });

  final CharacterSpec spec;
  final double t;
  final Mood mood;
  final bool calm;
  final bool shadow;

  static const _ink = Color(0xFF2B2440);
  static const _w = Colors.white;

  double get _tt => calm ? 0 : t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height) / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    if (shadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, 0.93),
          width: 1.1,
          height: 0.14,
        ),
        Paint()..color = const Color(0x22000000),
      );
    }
    // Idle-Wippen / Hüpfen
    final bob = calm
        ? 0.0
        : mood == Mood.happy
        ? -(math.sin(_tt * 7)).abs() * 0.12
        : mood == Mood.active
        ? math.sin(_tt * 4.5) * 0.025
        : math.sin(_tt * 1.8) * 0.018;
    canvas.translate(0, bob);
    final sway = (calm || mood == Mood.sleepy)
        ? 0.0
        : math.sin(_tt * 2.2) * 0.015;
    canvas.rotate(sway);
    _draw(canvas);
    if (mood == Mood.happy && !calm) _sparkles(canvas);
    if (mood == Mood.sleepy) _zzz(canvas);
    canvas.restore();
  }

  void _draw(Canvas c) {
    switch (spec.archetype) {
      case Archetype.critter:
        _critter(c, spec.critter!);
      case Archetype.bird:
        _bird(c);
      case Archetype.fish:
        _fish(c);
      case Archetype.whale:
        _whale(c);
      case Archetype.octopus:
        _octopus(c);
      case Archetype.turtle:
        _turtle(c);
      case Archetype.crab:
        _crab(c);
      case Archetype.dino:
        _dino(c);
      case Archetype.dragon:
        _dragon(c);
      case Archetype.robot:
        _robot(c);
      case Archetype.monster:
        _monster(c);
      case Archetype.vehicle:
        _vehicle(c);
      case Archetype.rocket:
        _rocket(c);
      case Archetype.ufo:
        _ufo(c);
      case Archetype.moon:
        _moon(c);
      case Archetype.planet:
        _planet(c);
      case Archetype.star:
        _star(c);
      case Archetype.sun:
        _sun(c);
      case Archetype.flower:
        _flower(c);
      case Archetype.tree:
        _tree(c);
      case Archetype.mushroom:
        _mushroom(c);
      case Archetype.snowman:
        _snowman(c);
      case Archetype.pumpkin:
        _pumpkin(c);
      case Archetype.egg:
        _egg(c);
      case Archetype.xmasTree:
        _xmas(c);
      case Archetype.jellyfish:
        _jellyfish(c);
      case Archetype.astronaut:
        _astronaut(c);
      case Archetype.cloud:
        _cloud(c);
      case Archetype.cactus:
        _cactus(c);
      case Archetype.ghost:
        _ghost(c);
      case Archetype.ladybug:
        _ladybug(c);
    }
  }

  // ---------- Helfer ----------
  Paint _f(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Color _shade(Color c, double amount) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  void _oval(Canvas c, double x, double y, double rx, double ry, Color col) =>
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2),
        _f(col),
      );

  bool get _blinking {
    if (calm) return false;
    final p = (_tt % 4.0);
    return p > 3.8;
  }

  /// Augen: Pupille, Glanzpunkt, Blinzeln, Schläfrigkeit.
  void _eyes(Canvas c, double x, double y, double gap, double r) {
    for (final sx in [-1.0, 1.0]) {
      final cx = x + sx * gap;
      final closed = _blinking || mood == Mood.sleepy;
      if (mood == Mood.happy) {
        // Fröhliche Bögen
        final p = Path()
          ..moveTo(cx - r, y + r * 0.3)
          ..quadraticBezierTo(cx, y - r * 1.2, cx + r, y + r * 0.3);
        c.drawPath(p, _stroke(_ink, r * 0.45));
      } else if (closed) {
        final p = Path()
          ..moveTo(cx - r, y)
          ..quadraticBezierTo(cx, y + r * 0.7, cx + r, y);
        c.drawPath(p, _stroke(_ink, r * 0.4));
      } else {
        _oval(c, cx, y, r, r * 1.15, _ink);
        _oval(c, cx + r * 0.3, y - r * 0.4, r * 0.38, r * 0.38, Colors.white);
      }
    }
  }

  void _cheeks(Canvas c, double x, double y, double gap, double r) {
    final col = const Color(0xFFFF8FA3).withValues(alpha: 0.45);
    _oval(c, x - gap, y, r, r * 0.7, col);
    _oval(c, x + gap, y, r, r * 0.7, col);
  }

  void _smile(Canvas c, double x, double y, double w) {
    final open = mood == Mood.happy;
    final p = Path()
      ..moveTo(x - w, y)
      ..quadraticBezierTo(x, y + w * (open ? 1.6 : 0.9), x + w, y);
    if (open) {
      p.close();
      c.drawPath(p, _f(const Color(0xFF8A2F3C)));
      c.drawPath(p, _stroke(_ink, w * 0.18));
      _oval(c, x, y + w * 0.62, w * 0.45, w * 0.28, const Color(0xFFFF7A8A));
    } else if (mood == Mood.sleepy) {
      c.drawLine(
        Offset(x - w * 0.5, y + w * 0.2),
        Offset(x + w * 0.5, y + w * 0.2),
        _stroke(_ink, w * 0.2),
      );
    } else {
      c.drawPath(p, _stroke(_ink, w * 0.2));
    }
  }

  void _sparkles(Canvas c) {
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + _tt * 1.5;
      final r = 0.95 + 0.06 * math.sin(_tt * 5 + i);
      final p = Offset(math.cos(a) * r, math.sin(a) * r * 0.9 - 0.1);
      _starShape(
        c,
        p,
        0.07 + 0.02 * math.sin(_tt * 6 + i),
        const Color(0xFFFFD84D),
      );
    }
  }

  void _starShape(Canvas c, Offset ctr, double r, Color col, {double rot = 0}) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + rot + i * math.pi / 5;
      final pt = Offset(ctr.dx + math.cos(a) * rad, ctr.dy + math.sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, _f(col));
  }

  void _zzz(Canvas c) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'z z',
        style: TextStyle(
          fontSize: 0.22,
          fontWeight: FontWeight.w800,
          color: _ink.withValues(alpha: 0.55),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, const Offset(0.5, -0.95));
  }

  // ---------- Tiere (Critter) ----------
  void _critter(Canvas c, CritterStyle s) {
    final tail = math.sin(_tt * 5) * 0.12;
    final neck = s.longNeck;
    final headY = neck ? -0.62 : -0.22;
    final headR = neck ? 0.42 : 0.52;

    // Schwanz
    if (s.tail) {
      final p = Path()
        ..moveTo(0.45, 0.45)
        ..quadraticBezierTo(0.85 + tail, 0.3, 0.75 + tail, 0.05);
      c.drawPath(
        p,
        _stroke(
          s.pattern == Pattern.stripes ? s.patternColor : _shade(s.body, -0.1),
          0.12,
        ),
      );
      if (s.mane) _oval(c, 0.75 + tail, 0.05, 0.1, 0.1, s.maneColor);
    }
    // Mähne hinter Kopf
    if (s.mane && s.ear == EarType.round) {
      _oval(c, 0, headY, headR + 0.2, headR + 0.2, s.maneColor);
      for (var i = 0; i < 12; i++) {
        final a = i * math.pi / 6;
        _oval(
          c,
          math.cos(a) * (headR + 0.16),
          headY + math.sin(a) * (headR + 0.16),
          0.13,
          0.13,
          s.maneColor,
        );
      }
    } else if (s.mane) {
      final p = Path()
        ..moveTo(-0.1, headY - headR)
        ..quadraticBezierTo(-0.62, headY, -0.5, headY + 0.75)
        ..lineTo(-0.2, headY + 0.5)
        ..close();
      c.drawPath(p, _f(s.maneColor));
    }
    // Hals
    if (neck) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-0.2, -0.65, 0.4, 1.0),
          const Radius.circular(0.18),
        ),
        _f(s.body),
      );
    }
    // Körper
    _oval(c, 0, 0.45, 0.58, 0.46, s.woolly ? s.body : s.body);
    if (s.woolly) {
      for (var i = 0; i < 9; i++) {
        final a = i * 2 * math.pi / 9;
        _oval(
          c,
          math.cos(a) * 0.5,
          0.45 + math.sin(a) * 0.38,
          0.2,
          0.2,
          s.body,
        );
      }
      _oval(c, 0, 0.45, 0.5, 0.4, s.body);
    }
    _oval(c, 0, 0.55, 0.34, 0.3, s.belly.withValues(alpha: s.woolly ? 0 : 1));
    // Muster am Körper
    _bodyPattern(c, s);
    // Füße
    final footCol = s.woolly ? s.belly : _shade(s.body, -0.07);
    _oval(c, -0.28, 0.9, 0.17, 0.09, footCol);
    _oval(c, 0.28, 0.9, 0.17, 0.09, footCol);

    // Ohren
    _ears(c, s, headY, headR);

    // Kopf
    if (s.woolly) {
      for (var i = 0; i < 7; i++) {
        final a = i * 2 * math.pi / 7 - math.pi / 2;
        _oval(
          c,
          math.cos(a) * 0.35,
          headY - 0.18 + math.sin(a) * 0.15,
          0.17,
          0.17,
          s.body,
        );
      }
      _oval(c, 0, headY + 0.04, headR - 0.06, headR - 0.04, s.belly);
    } else {
      _oval(c, 0, headY, headR, headR * 0.95, s.body);
      if (s.pattern == Pattern.patch) {
        // Fleck um ein Auge
        _oval(
          c,
          0.2,
          headY - 0.08,
          0.2,
          0.22,
          s.patternColor.withValues(alpha: 0.9),
        );
      }
      if (s.pattern == Pattern.stripes) {
        for (final dx in [-0.22, 0.0, 0.22]) {
          final p = Path()
            ..moveTo(dx - 0.04, headY - headR * 0.93)
            ..lineTo(dx + 0.04, headY - headR * 0.93)
            ..lineTo(dx, headY - headR * 0.55)
            ..close();
          c.drawPath(p, _f(s.patternColor));
        }
      }
      if (s.pattern == Pattern.spots && neck) {
        _oval(c, -0.2, headY - 0.1, 0.07, 0.06, s.patternColor);
        _oval(c, 0.18, headY - 0.22, 0.06, 0.05, s.patternColor);
      }
    }
    // Hörner / Horn
    if (s.horn) _horn(c, s, headY, headR);
    if (s.antlers) _antlers(c, s, headY, headR);

    // Schnauze
    _snout(c, s, headY, headR);

    // Gesicht
    final ey = headY - 0.04;
    if (s.eyePatch) {
      for (final sx in [-1.0, 1.0]) {
        c.save();
        c.translate(sx * headR * 0.45, ey);
        c.rotate(sx * 0.35);
        _oval(c, 0, 0, 0.13, 0.1, s.earColor ?? s.accent);
        c.restore();
      }
    }
    _eyes(c, 0, ey, headR * 0.45, 0.065);
    _cheeks(c, 0, headY + 0.14, headR * 0.7, 0.07);
    if (s.snout == Snout.none) {
      _oval(
        c,
        0,
        headY + 0.07,
        s.bigNose ? 0.08 : 0.045,
        s.bigNose ? 0.06 : 0.032,
        s.accent == s.body ? _ink : _shade(s.accent, -0.1),
      );
      _smile(c, 0, headY + 0.13, 0.09);
    } else if (s.snout == Snout.trunk) {
      // Mund bleibt unter Rüssel verdeckt
    } else {
      _smile(c, 0, headY + 0.24, 0.09);
    }
    if (s.whiskers) {
      for (final sx in [-1.0, 1.0]) {
        for (final dy in [-0.02, 0.05]) {
          c.drawLine(
            Offset(sx * 0.2, headY + 0.1 + dy),
            Offset(sx * 0.5, headY + 0.07 + dy * 2.2),
            _stroke(_ink.withValues(alpha: 0.5), 0.012),
          );
        }
      }
    }
  }

  void _bodyPattern(Canvas c, CritterStyle s) {
    switch (s.pattern) {
      case Pattern.spots:
        for (final o in const [
          Offset(-0.3, 0.35),
          Offset(0.25, 0.3),
          Offset(0.05, 0.62),
          Offset(-0.1, 0.2),
        ]) {
          _oval(c, o.dx, o.dy, 0.08, 0.07, s.patternColor);
        }
      case Pattern.stripes:
        for (final dx in [-0.35, -0.12, 0.12, 0.35]) {
          final p = Path()
            ..moveTo(dx, 0.02)
            ..quadraticBezierTo(dx + 0.05, 0.1, dx, 0.2);
          c.drawPath(p, _stroke(s.patternColor, 0.07));
        }
      case Pattern.patch:
        _oval(c, -0.28, 0.4, 0.2, 0.17, s.patternColor.withValues(alpha: 0.85));
        _oval(c, 0.3, 0.55, 0.14, 0.12, s.patternColor.withValues(alpha: 0.85));
      case Pattern.none:
        break;
    }
  }

  void _ears(Canvas c, CritterStyle s, double hy, double hr) {
    final wig = calm ? 0.0 : math.sin(_tt * 3) * 0.04;
    switch (s.ear) {
      case EarType.none:
        break;
      case EarType.round:
        for (final sx in [-1.0, 1.0]) {
          _oval(
            c,
            sx * hr * 0.78,
            hy - hr * 0.72,
            0.16,
            0.16,
            s.earColor ?? (s.mane ? s.maneColor : s.body),
          );
          _oval(
            c,
            sx * hr * 0.78,
            hy - hr * 0.72,
            0.09,
            0.09,
            s.earColor != null
                ? s.earColor!
                : (s.accent == s.body ? s.belly : s.accent),
          );
        }
      case EarType.tiny:
        for (final sx in [-1.0, 1.0]) {
          _oval(c, sx * hr * 0.7, hy - hr * 0.78, 0.11, 0.11, s.body);
          _oval(c, sx * hr * 0.7, hy - hr * 0.78, 0.065, 0.065, s.accent);
        }
      case EarType.pointy:
        for (final sx in [-1.0, 1.0]) {
          final p = Path()
            ..moveTo(sx * hr * 0.25, hy - hr * 0.85)
            ..lineTo(sx * hr * 0.95, hy - hr * 1.25 + wig * sx)
            ..lineTo(sx * hr * 0.98, hy - hr * 0.35)
            ..close();
          c.drawPath(p, _f(s.body));
          final q = Path()
            ..moveTo(sx * hr * 0.42, hy - hr * 0.8)
            ..lineTo(sx * hr * 0.88, hy - hr * 1.08 + wig * sx)
            ..lineTo(sx * hr * 0.9, hy - hr * 0.5)
            ..close();
          c.drawPath(q, _f(s.accent));
        }
      case EarType.long:
        for (final sx in [-1.0, 1.0]) {
          c.save();
          c.translate(sx * hr * 0.4, hy - hr * 0.8);
          c.rotate(sx * (0.18 + wig));
          _oval(c, 0, -0.33, 0.13, 0.4, s.body);
          _oval(c, 0, -0.33, 0.065, 0.3, s.accent);
          c.restore();
        }
      case EarType.floppy:
        for (final sx in [-1.0, 1.0]) {
          c.save();
          c.translate(sx * hr * 0.85, hy - hr * 0.55);
          c.rotate(sx * (0.45 + wig));
          _oval(
            c,
            0,
            0.12,
            0.14,
            0.3,
            s.pattern == Pattern.patch ? s.patternColor : _shade(s.body, -0.08),
          );
          c.restore();
        }
      case EarType.huge:
        for (final sx in [-1.0, 1.0]) {
          c.save();
          c.translate(sx * hr * 0.82, hy);
          c.rotate(sx * (0.12 + wig));
          _oval(c, sx * 0.22, 0, 0.3, 0.38, s.body);
          _oval(c, sx * 0.22, 0.02, 0.2, 0.28, s.accent);
          c.restore();
        }
    }
  }

  void _horn(Canvas c, CritterStyle s, double hy, double hr) {
    if (s.longNeck) {
      for (final sx in [-1.0, 1.0]) {
        c.drawLine(
          Offset(sx * 0.13, hy - hr * 0.9),
          Offset(sx * 0.17, hy - hr * 1.3),
          _stroke(s.accent, 0.05),
        );
        _oval(c, sx * 0.17, hy - hr * 1.33, 0.05, 0.05, s.accent);
      }
    } else if (s.maneColor == const Color(0xFFB57BE0)) {
      // Einhorn
      final p = Path()
        ..moveTo(-0.08, hy - hr * 0.85)
        ..lineTo(0.0, hy - hr * 1.75)
        ..lineTo(0.08, hy - hr * 0.85)
        ..close();
      c.drawPath(p, _f(const Color(0xFFFFD84D)));
      c.drawLine(
        Offset(-0.05, hy - hr * 1.1),
        Offset(0.05, hy - hr * 1.2),
        _stroke(const Color(0xFFE5A800), 0.02),
      );
      c.drawLine(
        Offset(-0.04, hy - hr * 1.4),
        Offset(0.04, hy - hr * 1.5),
        _stroke(const Color(0xFFE5A800), 0.02),
      );
    } else {
      // Kuh
      for (final sx in [-1.0, 1.0]) {
        final p = Path()
          ..moveTo(sx * 0.2, hy - hr * 0.85)
          ..quadraticBezierTo(
            sx * 0.42,
            hy - hr * 1.25,
            sx * 0.5,
            hy - hr * 1.0,
          );
        c.drawPath(p, _stroke(const Color(0xFFF1DDB0), 0.07));
      }
    }
  }

  void _snout(Canvas c, CritterStyle s, double hy, double hr) {
    switch (s.snout) {
      case Snout.none:
        break;
      case Snout.muzzle:
        _oval(c, 0, hy + 0.2, hr * 0.5, hr * 0.38, s.belly);
        _oval(c, 0, hy + 0.12, 0.07, 0.05, _ink);
      case Snout.pigNose:
        _oval(
          c,
          0,
          hy + 0.18,
          hr * 0.45,
          hr * 0.33,
          _shade(s.accent == s.body ? s.belly : s.accent, 0.0),
        );
        _oval(c, -0.09, hy + 0.18, 0.04, 0.06, _ink.withValues(alpha: 0.7));
        _oval(c, 0.09, hy + 0.18, 0.04, 0.06, _ink.withValues(alpha: 0.7));
      case Snout.trunk:
        final sw = calm ? 0.0 : math.sin(_tt * 2.5) * 0.04;
        final p = Path()
          ..moveTo(0, hy + 0.1)
          ..quadraticBezierTo(0.05 + sw, hy + 0.55, 0.25 + sw, hy + 0.55);
        c.drawPath(p, _stroke(s.body, 0.2));
        c.drawPath(p, _stroke(_shade(s.body, -0.05), 0.04));
      case Snout.beak:
        break;
    }
  }

  // ---------- Vogel ----------
  void _bird(Canvas c) {
    final flap = calm ? 0.0 : math.sin(_tt * 6) * 0.12;
    final hen = spec.id == 'chicken';
    final penguin = spec.id == 'penguin';
    final duck = spec.id == 'duck';
    final owl = spec.id == 'owl';
    // Schwanz
    for (var i = -1; i <= 1; i++) {
      c.save();
      c.translate(0.45, 0.45);
      c.rotate(-0.7 + i * 0.35);
      _oval(
        c,
        0.28,
        0,
        0.3,
        0.1,
        i == 0 ? spec.c1 : _shade(spec.c1, hen ? -0.08 : -0.12),
      );
      c.restore();
    }
    _oval(c, 0, 0.3, 0.6, 0.62, spec.c1);
    _oval(
      c,
      0,
      0.45,
      0.38,
      0.4,
      (hen || penguin)
          ? _w
          : (owl ? const Color(0xFFF1DDB0) : _shade(spec.c1, 0.2)),
    );
    // Flügel
    c.save();
    c.translate(-0.45, 0.25);
    c.rotate(0.3 + flap);
    _oval(c, 0, 0.2, 0.17, 0.34, _shade(spec.c1, -0.1));
    c.restore();
    c.save();
    c.translate(0.45, 0.25);
    c.rotate(-0.3 - flap);
    _oval(c, 0, 0.2, 0.17, 0.34, _shade(spec.c1, -0.1));
    c.restore();
    // Kamm / Federn
    if (penguin || duck) {
      // keine Haube
    } else if (owl) {
      for (final sx in [-1.0, 1.0]) {
        c.drawPath(
          Path()
            ..moveTo(sx * 0.12, -0.52)
            ..lineTo(sx * 0.3, -0.72)
            ..lineTo(sx * 0.38, -0.4)
            ..close(),
          _f(spec.c3),
        );
      }
    } else if (hen) {
      for (final dx in [-0.12, 0.0, 0.12]) {
        _oval(c, dx, -0.52, 0.09, 0.12, spec.c3);
      }
    } else {
      for (var i = 0; i < 3; i++) {
        c.save();
        c.translate(0, -0.45);
        c.rotate((i - 1) * 0.35);
        _oval(c, 0, -0.14, 0.05, 0.16, i == 1 ? spec.c3 : spec.c2);
        c.restore();
      }
    }
    // Schnabel
    if (owl) {
      for (final sx in [-1.0, 1.0]) {
        _oval(c, sx * 0.24, -0.14, 0.15, 0.15, _w);
      }
    }
    final b =
        duck
              ? (Path()..addOval(
                  Rect.fromCenter(
                    center: const Offset(0, 0.07),
                    width: 0.34,
                    height: 0.13,
                  ),
                ))
              : Path()
          ..moveTo(-0.11, 0.0)
          ..lineTo(0.11, 0.0)
          ..lineTo(0, 0.16)
          ..close();
    c.drawPath(b, _f(spec.c2));
    if (hen) {
      _oval(c, 0, 0.2, 0.05, 0.08, spec.c3);
    }
    _eyes(c, 0, -0.14, 0.24, 0.07);
    _cheeks(c, 0, 0.04, 0.38, 0.08);
    // Füße
    c.drawLine(
      const Offset(-0.18, 0.88),
      const Offset(-0.18, 0.95),
      _stroke(spec.c2, 0.06),
    );
    c.drawLine(
      const Offset(0.18, 0.88),
      const Offset(0.18, 0.95),
      _stroke(spec.c2, 0.06),
    );
  }

  // ---------- Meer ----------
  void _fish(Canvas c) {
    final wag = calm ? 0.0 : math.sin(_tt * 5) * 0.12;
    c.save();
    c.translate(0, 0.1);
    final tail = Path()
      ..moveTo(0.4, 0)
      ..lineTo(0.9, -0.38 + wag)
      ..quadraticBezierTo(0.75, 0, 0.9, 0.38 + wag)
      ..close();
    c.drawPath(tail, _f(_shade(spec.c1, -0.08)));
    final fin = Path()
      ..moveTo(-0.1, -0.4)
      ..quadraticBezierTo(0.1, -0.8, 0.35, -0.38)
      ..close();
    c.drawPath(fin, _f(_shade(spec.c1, -0.08)));
    _oval(c, 0, 0, 0.6, 0.48, spec.c1);
    for (final dx in [0.05, 0.22]) {
      c.drawLine(
        Offset(dx, -0.32),
        Offset(dx, 0.32),
        _stroke(_w.withValues(alpha: 0.85), 0.08),
      );
    }
    _oval(c, -0.2, 0.18, 0.28, 0.2, spec.c2.withValues(alpha: 0.8));
    _eyes(c, -0.28, -0.1, 0, 0.08);
    _smile(c, -0.42, 0.13, 0.07);
    _cheeks(c, -0.2, 0.05, 0.0, 0.07);
    // Flosse
    c.save();
    c.translate(0.0, 0.1);
    c.rotate(wag);
    _oval(c, 0, 0.1, 0.1, 0.17, _shade(spec.c1, -0.12));
    c.restore();
    // Blasen
    if (!calm) {
      final b = (_tt * 0.5) % 1;
      c.drawCircle(
        Offset(-0.7, -0.2 - b * 0.5),
        0.05,
        _stroke(Colors.white.withValues(alpha: 1 - b), 0.015),
      );
    }
    c.restore();
  }

  void _whale(Canvas c) {
    final wag = calm ? 0.0 : math.sin(_tt * 3) * 0.1;
    final tail = Path()
      ..moveTo(0.55, 0.2)
      ..quadraticBezierTo(0.9, 0.0 + wag, 0.85, -0.3 + wag)
      ..quadraticBezierTo(0.95, -0.05, 1.0, -0.05 + wag)
      ..quadraticBezierTo(0.95, 0.15, 0.9, 0.25)
      ..close();
    c.drawPath(tail, _f(spec.c1));
    _oval(c, -0.05, 0.25, 0.75, 0.55, spec.c1);
    final belly = Path()
      ..addOval(
        Rect.fromCenter(
          center: const Offset(-0.1, 0.45),
          width: 1.2,
          height: 0.5,
        ),
      );
    c.save();
    c.clipPath(
      Path()..addOval(
        Rect.fromCenter(
          center: const Offset(-0.05, 0.25),
          width: 1.5,
          height: 1.1,
        ),
      ),
    );
    c.drawPath(belly, _f(spec.c2));
    c.restore();
    // Fontäne
    if (!calm) {
      final p = (_tt * 0.8) % 1;
      for (final dx in [-0.08, 0.08]) {
        c.drawLine(
          Offset(-0.2, -0.28),
          Offset(
            -0.2 + dx * 3,
            -0.28 - 0.35 * (0.5 + 0.5 * math.sin(p * math.pi)),
          ),
          _stroke(const Color(0xFF9DD6F5), 0.04),
        );
      }
    } else {
      c.drawLine(
        const Offset(-0.2, -0.28),
        const Offset(-0.2, -0.5),
        _stroke(const Color(0xFF9DD6F5), 0.04),
      );
    }
    _eyes(c, -0.35, 0.12, 0, 0.08);
    _cheeks(c, -0.3, 0.3, 0.1, 0.08);
    _smile(c, -0.38, 0.33, 0.12);
  }

  void _octopus(Canvas c) {
    for (var i = 0; i < 5; i++) {
      final x = -0.5 + i * 0.25;
      final w = calm ? 0.0 : math.sin(_tt * 3 + i) * 0.06;
      final p = Path()
        ..moveTo(x, 0.35)
        ..quadraticBezierTo(x + w + 0.1, 0.65, x - 0.05 + w, 0.8)
        ..quadraticBezierTo(x + 0.02 + w, 0.9, x + 0.1 + w, 0.85);
      c.drawPath(p, _stroke(spec.c1, 0.16));
    }
    _oval(c, 0, -0.1, 0.62, 0.64, spec.c1);
    for (final o in const [
      Offset(-0.3, -0.5),
      Offset(0.28, -0.4),
      Offset(0, -0.62),
    ]) {
      _oval(c, o.dx, o.dy, 0.06, 0.05, spec.c2);
    }
    _eyes(c, 0, -0.08, 0.25, 0.08);
    _cheeks(c, 0, 0.1, 0.38, 0.08);
    _smile(c, 0, 0.12, 0.1);
  }

  void _turtle(Canvas c) {
    _oval(c, -0.5, 0.15, 0.3, 0.28, spec.c1);
    for (final dx in [-0.35, 0.35]) {
      _oval(c, dx, 0.85, 0.15, 0.1, spec.c1);
    }
    _oval(c, 0.1, 0.35, 0.7, 0.55, spec.c3);
    _oval(c, 0.1, 0.3, 0.6, 0.47, spec.c2);
    for (final o in const [
      Offset(0.1, 0.1),
      Offset(-0.2, 0.3),
      Offset(0.4, 0.3),
      Offset(0.1, 0.5),
    ]) {
      final hex = Path();
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        final p = Offset(o.dx + math.cos(a) * 0.16, o.dy + math.sin(a) * 0.14);
        i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
      }
      hex.close();
      c.drawPath(hex, _f(spec.c3.withValues(alpha: 0.55)));
    }
    _eyes(c, -0.52, 0.1, 0.1, 0.05);
    _cheeks(c, -0.52, 0.25, 0.14, 0.05);
    _smile(c, -0.52, 0.28, 0.07);
  }

  void _crab(Canvas c) {
    final snap = calm ? 0.0 : math.sin(_tt * 4) * 0.15;
    for (final sx in [-1.0, 1.0]) {
      c.save();
      c.translate(sx * 0.62, -0.1);
      c.rotate(sx * (0.2 + snap));
      c.drawLine(Offset.zero, Offset(sx * 0.1, -0.2), _stroke(spec.c1, 0.1));
      _oval(c, sx * 0.1, -0.35, 0.2, 0.2, spec.c1);
      _oval(c, sx * 0.1, -0.5, 0.06, 0.1, _shade(spec.c1, -0.15));
      c.restore();
      for (final dy in [0.4, 0.58, 0.76]) {
        c.drawLine(
          Offset(sx * 0.45, dy),
          Offset(sx * 0.8, dy + 0.1),
          _stroke(_shade(spec.c1, -0.08), 0.07),
        );
      }
      c.drawLine(
        Offset(sx * 0.2, -0.45),
        Offset(sx * 0.2, -0.7),
        _stroke(spec.c1, 0.05),
      );
      _oval(c, sx * 0.2, -0.72, 0.09, 0.09, _w);
      _oval(c, sx * 0.2, -0.72, 0.045, 0.045, _ink);
    }
    _oval(c, 0, 0.3, 0.62, 0.5, spec.c1);
    _oval(c, 0, 0.45, 0.4, 0.3, spec.c2.withValues(alpha: 0.6));
    _cheeks(c, 0, 0.32, 0.3, 0.07);
    _smile(c, 0, 0.3, 0.12);
  }

  // ---------- Dinos / Drache / Roboter / Monster ----------
  void _dino(Canvas c) {
    final id = spec.id;
    final long = id == 'brachio';
    final wag = calm ? 0.0 : math.sin(_tt * 3) * 0.06;
    // Schwanz
    final tail = Path()
      ..moveTo(0.35, 0.35)
      ..quadraticBezierTo(0.9, 0.55 + wag, 0.95, 0.15 + wag)
      ..quadraticBezierTo(0.75, 0.4, 0.4, 0.7)
      ..close();
    c.drawPath(tail, _f(spec.c1));
    // Rückenplatten
    if (id == 'stego') {
      for (var i = 0; i < 5; i++) {
        final x = -0.2 + i * 0.17;
        final p = Path()
          ..moveTo(x - 0.1, 0.0 + i * 0.03)
          ..lineTo(x, -0.28 + i * 0.03 + (i == 2 ? -0.08 : 0))
          ..lineTo(x + 0.1, 0.0 + i * 0.03)
          ..close();
        c.drawPath(p, _f(spec.c3));
      }
    } else if (id == 'trex') {
      for (var i = 0; i < 4; i++) {
        final x = 0.05 + i * 0.14;
        final p = Path()
          ..moveTo(x - 0.05, 0.05 + i * 0.07)
          ..lineTo(x, -0.1 + i * 0.07)
          ..lineTo(x + 0.05, 0.05 + i * 0.07)
          ..close();
        c.drawPath(p, _f(_shade(spec.c1, -0.12)));
      }
    }
    // Hals bei Langhals
    if (long) {
      c.drawPath(
        Path()
          ..moveTo(-0.35, 0.35)
          ..quadraticBezierTo(-0.7, 0.0, -0.45, -0.6)
          ..lineTo(-0.2, -0.55)
          ..quadraticBezierTo(-0.35, 0.0, -0.05, 0.3)
          ..close(),
        _f(spec.c1),
      );
    }
    _oval(c, 0, 0.45, 0.62, 0.45, spec.c1);
    _oval(c, 0, 0.58, 0.4, 0.3, spec.c2);
    if (id == 'brachio') {
      for (final o in const [
        Offset(0.2, 0.3),
        Offset(0.4, 0.45),
        Offset(0.0, 0.2),
      ]) {
        _oval(c, o.dx, o.dy, 0.07, 0.06, spec.c3);
      }
    }
    // Füße
    _oval(c, -0.28, 0.9, 0.17, 0.09, _shade(spec.c1, -0.08));
    _oval(c, 0.28, 0.9, 0.17, 0.09, _shade(spec.c1, -0.08));
    // Kopf
    final hx = long ? -0.32 : -0.12;
    final hy = long ? -0.6 : -0.22;
    final hr = long ? 0.28 : 0.46;
    if (id == 'tricera') {
      // Nackenschild
      _oval(c, hx, hy - 0.04, hr + 0.3, hr + 0.22, spec.c3);
      for (var i = 0; i < 7; i++) {
        final a = math.pi + i * math.pi / 6;
        _oval(
          c,
          hx + math.cos(a) * (hr + 0.28),
          hy - 0.04 + math.sin(a) * (hr + 0.2),
          0.07,
          0.07,
          _shade(spec.c3, -0.15),
        );
      }
    }
    _oval(c, hx, hy, hr, hr * 0.95, spec.c1);
    if (id == 'tricera') {
      for (final dx in [-0.15, 0.15]) {
        c.drawPath(
          Path()
            ..moveTo(hx + dx - 0.05, hy - 0.25)
            ..lineTo(hx + dx * 1.3, hy - 0.62)
            ..lineTo(hx + dx + 0.05, hy - 0.25)
            ..close(),
          _f(_w),
        );
      }
      c.drawPath(
        Path()
          ..moveTo(hx - 0.04, hy + 0.05)
          ..lineTo(hx, hy - 0.22)
          ..lineTo(hx + 0.04, hy + 0.05)
          ..close(),
        _f(_w),
      );
    }
    if (id == 'trex') {
      _oval(c, hx - 0.05, hy + 0.2, hr * 0.7, hr * 0.38, spec.c2);
      c.drawLine(
        Offset(hx - 0.2, hy + 0.17),
        Offset(hx - 0.14, hy + 0.27),
        _stroke(_w, 0.035),
      );
      c.drawLine(
        Offset(hx + 0.05, hy + 0.17),
        Offset(hx + 0.0, hy + 0.27),
        _stroke(_w, 0.035),
      );
    }
    _eyes(c, hx, hy - 0.05, hr * 0.42, hr < 0.35 ? 0.05 : 0.065);
    _cheeks(c, hx, hy + 0.1, hr * 0.7, 0.06);
    if (id != 'trex') _smile(c, hx, hy + 0.15, 0.09);
    // Ärmchen
    c.drawLine(
      Offset(hx + 0.35, 0.3),
      Offset(hx + 0.5, 0.45),
      _stroke(spec.c1, 0.09),
    );
  }

  void _dragon(Canvas c) {
    final flap = calm ? 0.0 : math.sin(_tt * 4) * 0.15;
    for (final sx in [-1.0, 1.0]) {
      final wing = Path()
        ..moveTo(sx * 0.35, 0.15)
        ..quadraticBezierTo(sx * 1.0, -0.55 + flap, sx * 0.95, -0.1)
        ..quadraticBezierTo(sx * 0.8, 0.05, sx * 0.7, 0.05)
        ..quadraticBezierTo(sx * 0.6, 0.2, sx * 0.4, 0.3)
        ..close();
      c.drawPath(wing, _f(spec.c3));
    }
    final tail = Path()
      ..moveTo(0.35, 0.5)
      ..quadraticBezierTo(0.9, 0.7, 0.9, 0.3)
      ..quadraticBezierTo(0.7, 0.55, 0.4, 0.75)
      ..close();
    c.drawPath(tail, _f(spec.c1));
    _oval(c, 0.9, 0.3, 0.07, 0.07, spec.c3);
    _oval(c, 0, 0.45, 0.55, 0.46, spec.c1);
    _oval(c, 0, 0.55, 0.34, 0.33, spec.c2);
    _oval(c, -0.25, 0.9, 0.15, 0.08, _shade(spec.c1, -0.08));
    _oval(c, 0.25, 0.9, 0.15, 0.08, _shade(spec.c1, -0.08));
    for (final sx in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(sx * 0.2, -0.55)
          ..lineTo(sx * 0.3, -0.85)
          ..lineTo(sx * 0.4, -0.5)
          ..close(),
        _f(spec.c3),
      );
    }
    _oval(c, 0, -0.2, 0.5, 0.46, spec.c1);
    _oval(c, 0, -0.03, 0.27, 0.2, spec.c2);
    _oval(c, -0.08, -0.06, 0.03, 0.025, _ink);
    _oval(c, 0.08, -0.06, 0.03, 0.025, _ink);
    _eyes(c, 0, -0.3, 0.22, 0.065);
    _cheeks(c, 0, -0.1, 0.38, 0.06);
    _smile(c, 0, 0.04, 0.08);
    // Flämmchen
    if (!calm) {
      final f = 0.5 + 0.5 * math.sin(_tt * 8);
      final p = Path()
        ..moveTo(0.28, 0.0)
        ..quadraticBezierTo(0.45 + f * 0.08, -0.08, 0.55, 0.0)
        ..quadraticBezierTo(0.45, 0.08, 0.28, 0.04)
        ..close();
      c.drawPath(
        p,
        _f(spec.c3.withValues(alpha: mood == Mood.happy ? 0.9 : 0.0)),
      );
    }
  }

  void _robot(Canvas c) {
    final blink = calm ? 1.0 : (0.6 + 0.4 * math.sin(_tt * 4)).abs();
    c.drawLine(
      const Offset(0, -0.85),
      const Offset(0, -0.62),
      _stroke(spec.c1, 0.04),
    );
    c.drawCircle(
      const Offset(0, -0.88),
      0.07,
      _f(Color.lerp(spec.c3, _w, 1 - blink)!),
    );
    for (final sx in [-1.0, 1.0]) {
      _oval(c, sx * 0.62, 0.35, 0.1, 0.25, _shade(spec.c1, -0.1));
      _oval(c, sx * 0.25, 0.9, 0.17, 0.08, _shade(spec.c1, -0.15));
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.5, 0.0, 1.0, 0.85),
        const Radius.circular(0.16),
      ),
      _f(spec.c1),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.3, 0.2, 0.6, 0.45),
        const Radius.circular(0.1),
      ),
      _f(spec.c2),
    );
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
        Offset(-0.15 + i * 0.15, 0.42),
        0.04,
        _f([spec.c3, const Color(0xFF58B368), const Color(0xFFE5574B)][i]),
      );
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.55, -0.62, 1.1, 0.7),
        const Radius.circular(0.2),
      ),
      _f(spec.c1),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.42, -0.5, 0.84, 0.46),
        const Radius.circular(0.14),
      ),
      _f(const Color(0xFF263248)),
    );
    final eyeCol = mood == Mood.sleepy
        ? const Color(0xFF6FA8D8)
        : const Color(0xFF7FE0FF);
    for (final sx in [-1.0, 1.0]) {
      if (mood == Mood.sleepy || _blinking) {
        c.drawLine(
          Offset(sx * 0.17 - 0.07, -0.28),
          Offset(sx * 0.17 + 0.07, -0.28),
          _stroke(eyeCol, 0.04),
        );
      } else {
        _oval(c, sx * 0.17, -0.28, 0.07, 0.08, eyeCol);
      }
    }
    final m = Path()
      ..moveTo(-0.1, -0.15)
      ..quadraticBezierTo(0, mood == Mood.happy ? -0.02 : -0.08, 0.1, -0.15);
    c.drawPath(m, _stroke(eyeCol, 0.03));
  }

  void _monster(Canvas c) {
    final sway = calm ? 0.0 : math.sin(_tt * 3) * 0.03;
    for (final sx in [-1.0, 1.0]) {
      _oval(c, sx * 0.62, 0.35 + sway * sx, 0.14, 0.2, _shade(spec.c1, -0.06));
      _oval(c, sx * 0.25, 0.9, 0.17, 0.08, _shade(spec.c1, -0.1));
      c.drawLine(
        Offset(sx * 0.25, -0.5),
        Offset(sx * 0.32, -0.8),
        _stroke(spec.c1, 0.04),
      );
      _oval(c, sx * 0.32, -0.83, 0.07, 0.07, spec.c3);
    }
    _oval(c, 0, 0.1, 0.7, 0.8, spec.c1);
    _oval(c, 0, 0.5, 0.42, 0.32, spec.c2);
    // Fell-Zotteln
    for (var i = 0; i < 6; i++) {
      final a = math.pi + (i + 0.5) * math.pi / 6;
      final p = Path()
        ..moveTo(math.cos(a - 0.12) * 0.7, 0.1 + math.sin(a - 0.12) * 0.8)
        ..lineTo(math.cos(a) * 0.82, 0.1 + math.sin(a) * 0.92)
        ..lineTo(math.cos(a + 0.12) * 0.7, 0.1 + math.sin(a + 0.12) * 0.8);
      c.drawPath(p, _f(spec.c1));
    }
    // Ein großes Auge
    _oval(c, 0, -0.12, 0.28, 0.28, _w);
    if (mood == Mood.sleepy || _blinking) {
      c.drawLine(
        const Offset(-0.2, -0.12),
        const Offset(0.2, -0.12),
        _stroke(_ink, 0.05),
      );
    } else {
      _oval(c, 0.04, -0.1, 0.14, 0.14, spec.c3);
      _oval(c, 0.04, -0.1, 0.08, 0.08, _ink);
      _oval(c, 0.08, -0.14, 0.03, 0.03, _w);
    }
    final mouth = Path()
      ..moveTo(-0.25, 0.28)
      ..quadraticBezierTo(0, mood == Mood.happy ? 0.62 : 0.5, 0.25, 0.28)
      ..close();
    c.drawPath(mouth, _f(const Color(0xFF7A2F4A)));
    for (final dx in [-0.12, 0.0, 0.12]) {
      c.drawPath(
        Path()
          ..moveTo(dx - 0.04, 0.3)
          ..lineTo(dx, 0.38)
          ..lineTo(dx + 0.04, 0.3)
          ..close(),
        _f(_w),
      );
    }
  }

  // ---------- Fahrzeuge ----------
  void _wheel(Canvas c, double x, double y, double r) {
    c.drawCircle(Offset(x, y), r, _f(const Color(0xFF3A3A4A)));
    c.drawCircle(Offset(x, y), r * 0.5, _f(const Color(0xFFCBD2DC)));
    if (!calm) {
      final a = _tt * (mood == Mood.active ? 6 : 1);
      c.drawLine(
        Offset(x + math.cos(a) * r * 0.4, y + math.sin(a) * r * 0.4),
        Offset(x - math.cos(a) * r * 0.4, y - math.sin(a) * r * 0.4),
        _stroke(const Color(0xFF3A3A4A), r * 0.15),
      );
    }
  }

  void _vehicleFace(Canvas c, double x, double y) {
    _eyes(c, x, y, 0.1, 0.055);
    _smile(c, x, y + 0.14, 0.07);
  }

  void _vehicle(Canvas c) {
    switch (spec.id) {
      case 'car':
        c.drawPath(
          Path()
            ..moveTo(-0.45, 0.1)
            ..quadraticBezierTo(-0.35, -0.5, 0.0, -0.5)
            ..quadraticBezierTo(0.35, -0.5, 0.45, 0.1)
            ..close(),
          _f(spec.c1),
        );
        c.drawPath(
          Path()
            ..moveTo(-0.34, 0.05)
            ..quadraticBezierTo(-0.28, -0.38, 0.0, -0.38)
            ..quadraticBezierTo(0.28, -0.38, 0.34, 0.05)
            ..close(),
          _f(spec.c2),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.85, 0.0, 1.7, 0.6),
            const Radius.circular(0.2),
          ),
          _f(spec.c1),
        );
        _oval(c, 0.78, 0.2, 0.07, 0.07, const Color(0xFFFFE680));
        _wheel(c, -0.5, 0.65, 0.2);
        _wheel(c, 0.5, 0.65, 0.2);
        _vehicleFace(c, 0, -0.18);
      case 'train':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.8, -0.1, 1.2, 0.7),
            const Radius.circular(0.12),
          ),
          _f(spec.c1),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.15, -0.55, 0.55, 0.65),
            const Radius.circular(0.1),
          ),
          _f(_shade(spec.c1, -0.08)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.25, -0.45, 0.35, 0.3),
            const Radius.circular(0.06),
          ),
          _f(spec.c2),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.55, -0.45, 0.28, 0.4),
            const Radius.circular(0.05),
          ),
          _f(const Color(0xFF3A3A4A)),
        );
        final puff = calm ? 0.0 : (_tt * 0.7) % 1;
        c.drawCircle(
          Offset(-0.41 - puff * 0.15, -0.55 - puff * 0.35),
          0.1 + puff * 0.08,
          _f(Colors.white.withValues(alpha: 0.85 - puff * 0.7)),
        );
        _eyes(c, -0.2, 0.15, 0.18, 0.06);
        _smile(c, -0.2, 0.32, 0.09);
        _wheel(c, -0.55, 0.65, 0.17);
        _wheel(c, -0.1, 0.65, 0.17);
        _wheel(c, 0.45, 0.65, 0.17);
      case 'tractor':
        _wheel(c, -0.5, 0.55, 0.3);
        _wheel(c, 0.5, 0.7, 0.18);
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.2, -0.45, 0.6, 0.5),
            const Radius.circular(0.08),
          ),
          _f(spec.c1),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.12, -0.38, 0.44, 0.32),
            const Radius.circular(0.06),
          ),
          _f(spec.c2),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.2, 0.0, 1.0, 0.45),
            const Radius.circular(0.12),
          ),
          _f(spec.c1),
        );
        c.drawRect(
          const Rect.fromLTWH(0.62, -0.2, 0.06, 0.22),
          _f(const Color(0xFF3A3A4A)),
        );
        _eyes(c, 0.4, 0.14, 0.1, 0.05);
        _smile(c, 0.4, 0.28, 0.06);
        _wheel(c, -0.5, 0.55, 0.3);
      case 'boat':
        final puff = calm ? 0.0 : math.sin(_tt * 2) * 0.03;
        c.drawRect(const Rect.fromLTWH(-0.12, -0.55, 0.24, 0.4), _f(_w));
        c.drawRect(
          const Rect.fromLTWH(-0.14, -0.6, 0.28, 0.07),
          _f(const Color(0xFFE5574B)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.4, -0.2, 0.8, 0.3),
            const Radius.circular(0.06),
          ),
          _f(_w),
        );
        for (final dx in [-0.25, 0.0, 0.25]) {
          c.drawCircle(Offset(dx, -0.05), 0.06, _f(spec.c2));
        }
        c.drawPath(
          Path()
            ..moveTo(-0.85, 0.05)
            ..lineTo(0.85, 0.05)
            ..lineTo(0.6, 0.55)
            ..lineTo(-0.6, 0.55)
            ..close(),
          _f(spec.c1),
        );
        _eyes(c, 0, 0.22, 0.2, 0.055);
        _smile(c, 0, 0.36, 0.08);
        final w = Path()..moveTo(-1.0, 0.62 + puff);
        for (var i = 0; i < 6; i++) {
          w.quadraticBezierTo(
            -0.9 + i * 0.35 + 0.1,
            0.5 + puff,
            -0.9 + i * 0.35 + 0.35,
            0.62 + puff,
          );
        }
        w.lineTo(1.0, 0.9);
        w.lineTo(-1.0, 0.9);
        w.close();
        c.drawPath(w, _f(const Color(0xAA3D9BE0)));
      case 'plane':
        final prop = calm ? 0.0 : _tt * 20;
        c.drawPath(
          Path()
            ..moveTo(-0.2, 0.15)
            ..lineTo(0.35, 0.95)
            ..lineTo(0.6, 0.95)
            ..lineTo(0.3, 0.1)
            ..close(),
          _f(_shade(spec.c1, -0.08)),
        );
        c.drawPath(
          Path()
            ..moveTo(0.7, 0.05)
            ..lineTo(0.95, -0.4)
            ..lineTo(0.78, -0.4)
            ..lineTo(0.45, 0.0)
            ..close(),
          _f(_shade(spec.c1, -0.08)),
        );
        _oval(c, 0, 0.1, 0.8, 0.38, spec.c1);
        _oval(c, -0.1, -0.02, 0.35, 0.16, spec.c2);
        _oval(
          c,
          -0.8,
          0.1,
          0.07,
          0.22 * (0.6 + 0.4 * math.cos(prop)).abs() + 0.03,
          const Color(0xFF3A3A4A),
        );
        _eyes(c, -0.1, 0.0, 0.1, 0.055);
        _smile(c, -0.1, 0.18, 0.08);
      case 'bus':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.9, -0.3, 1.8, 0.9),
            const Radius.circular(0.16),
          ),
          _f(spec.c1),
        );
        c.drawRect(
          const Rect.fromLTWH(-0.9, 0.2, 1.8, 0.06),
          _f(const Color(0xFF3A3A4A)),
        );
        for (var i = 0; i < 3; i++) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(-0.8 + i * 0.4, -0.2, 0.3, 0.3),
              const Radius.circular(0.05),
            ),
            _f(spec.c2),
          );
        }
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.42, -0.2, 0.4, 0.4),
            const Radius.circular(0.06),
          ),
          _f(spec.c2),
        );
        _eyes(c, 0.62, -0.03, 0.1, 0.05);
        _smile(c, 0.62, 0.1, 0.06);
        _wheel(c, -0.5, 0.65, 0.19);
        _wheel(c, 0.5, 0.65, 0.19);
      case 'firetruck':
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-0.9, -0.1, 1.8, 0.7),
            const Radius.circular(0.12),
          ),
          _f(spec.c1),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.3, -0.4, 0.55, 0.5),
            const Radius.circular(0.1),
          ),
          _f(_shade(spec.c1, -0.06)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.4, -0.3, 0.35, 0.3),
            const Radius.circular(0.05),
          ),
          _f(spec.c2),
        );
        for (var i = 0; i < 5; i++) {
          c.drawLine(
            Offset(-0.75 + i * 0.22, -0.28),
            Offset(-0.75 + i * 0.22, -0.1),
            _stroke(const Color(0xFFCBD2DC), 0.03),
          );
        }
        c.drawLine(
          const Offset(-0.78, -0.28),
          const Offset(0.2, -0.28),
          _stroke(const Color(0xFFCBD2DC), 0.05),
        );
        c.drawLine(
          const Offset(-0.78, -0.2),
          const Offset(0.2, -0.2),
          _stroke(const Color(0xFFCBD2DC), 0.05),
        );
        final blink = calm || (_tt * 4).floor().isEven;
        c.drawCircle(
          const Offset(0.58, -0.45),
          0.06,
          _f(blink ? const Color(0xFF3F8FD9) : const Color(0xFF9CC5F0)),
        );
        _eyes(c, 0.575, -0.14, 0.09, 0.045);
        _smile(c, 0.575, -0.02, 0.05);
        _wheel(c, -0.55, 0.62, 0.19);
        _wheel(c, -0.05, 0.62, 0.19);
        _wheel(c, 0.6, 0.62, 0.19);
      case 'heli':
        final spin = calm ? 0.0 : math.cos(_tt * 25);
        c.drawLine(
          const Offset(0.2, 0.05),
          const Offset(0.95, -0.15),
          _stroke(_shade(spec.c1, -0.1), 0.12),
        );
        c.drawLine(
          const Offset(0.95, -0.35),
          const Offset(0.95, 0.05),
          _stroke(const Color(0xFF3A3A4A), 0.04 + 0.03 * spin.abs()),
        );
        c.drawLine(
          const Offset(0.0, -0.5),
          const Offset(0.0, -0.35),
          _stroke(const Color(0xFF3A3A4A), 0.05),
        );
        c.drawLine(
          Offset(-0.85 * (0.4 + 0.6 * spin.abs()), -0.52),
          Offset(0.85 * (0.4 + 0.6 * spin.abs()), -0.52),
          _stroke(const Color(0xFF3A3A4A), 0.05),
        );
        _oval(c, -0.05, 0.1, 0.6, 0.42, spec.c1);
        c.drawArc(
          Rect.fromCenter(
            center: const Offset(-0.3, 0.0),
            width: 0.55,
            height: 0.5,
          ),
          math.pi,
          math.pi * 1.1,
          true,
          _f(spec.c2),
        );
        _eyes(c, -0.3, -0.02, 0.1, 0.05);
        _smile(c, -0.3, 0.12, 0.06);
        c.drawLine(
          const Offset(-0.45, 0.62),
          const Offset(0.45, 0.62),
          _stroke(const Color(0xFF3A3A4A), 0.04),
        );
        c.drawLine(
          const Offset(-0.25, 0.45),
          const Offset(-0.3, 0.62),
          _stroke(const Color(0xFF3A3A4A), 0.04),
        );
        c.drawLine(
          const Offset(0.25, 0.45),
          const Offset(0.3, 0.62),
          _stroke(const Color(0xFF3A3A4A), 0.04),
        );
      default:
        break;
    }
  }

  // ---------- Weltraum ----------
  void _rocket(Canvas c) {
    final flame = calm ? 0.0 : math.sin(_tt * 18) * 0.05;
    c.drawPath(
      Path()
        ..moveTo(-0.2, 0.7)
        ..quadraticBezierTo(0, 1.1 + flame, 0.2, 0.7)
        ..close(),
      _f(spec.c3),
    );
    c.drawPath(
      Path()
        ..moveTo(-0.1, 0.7)
        ..quadraticBezierTo(0, 0.95 + flame, 0.1, 0.7)
        ..close(),
      _f(const Color(0xFFFFF0A8)),
    );
    for (final sx in [-1.0, 1.0]) {
      c.drawPath(
        Path()
          ..moveTo(sx * 0.3, 0.1)
          ..quadraticBezierTo(sx * 0.7, 0.4, sx * 0.55, 0.8)
          ..lineTo(sx * 0.25, 0.65)
          ..close(),
        _f(spec.c1),
      );
    }
    c.drawPath(
      Path()
        ..moveTo(0, -0.95)
        ..quadraticBezierTo(0.5, -0.5, 0.38, 0.72)
        ..lineTo(-0.38, 0.72)
        ..quadraticBezierTo(-0.5, -0.5, 0, -0.95)
        ..close(),
      _f(spec.c2),
    );
    c.drawPath(
      Path()
        ..moveTo(0, -0.95)
        ..quadraticBezierTo(0.28, -0.7, 0.34, -0.45)
        ..lineTo(-0.34, -0.45)
        ..quadraticBezierTo(-0.28, -0.7, 0, -0.95)
        ..close(),
      _f(spec.c1),
    );
    c.drawCircle(const Offset(0, -0.1), 0.24, _f(const Color(0xFF3D6FA8)));
    c.drawCircle(const Offset(0, -0.1), 0.2, _f(const Color(0xFF9ED8F5)));
    _eyes(c, 0, -0.12, 0.07, 0.04);
    _smile(c, 0, 0.0, 0.05);
    c.drawRect(const Rect.fromLTWH(-0.38, 0.38, 0.76, 0.07), _f(spec.c1));
  }

  void _ufo(Canvas c) {
    final hov = calm ? 0.0 : math.sin(_tt * 2.5) * 0.03;
    c.translate(0, hov);
    c.drawPath(
      Path()
        ..moveTo(-0.2, 0.35)
        ..lineTo(-0.5, 0.95)
        ..lineTo(0.5, 0.95)
        ..lineTo(0.2, 0.35)
        ..close(),
      _f(spec.c3.withValues(alpha: 0.28)),
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(0, -0.1), width: 0.8, height: 0.9),
      math.pi,
      math.pi,
      true,
      _f(const Color(0xFFBFE9F7)),
    );
    _oval(c, 0, 0.2, 0.95, 0.3, spec.c1);
    for (var i = 0; i < 5; i++) {
      final on = calm || ((_tt * 4).floor() + i) % 2 == 0;
      c.drawCircle(
        Offset(-0.6 + i * 0.3, 0.22),
        0.06,
        _f(on ? spec.c3 : _shade(spec.c3, -0.25)),
      );
    }
    _oval(c, 0, -0.18, 0.12, 0.14, spec.c2);
    _eyes(c, 0, -0.2, 0.05, 0.03);
    _oval(c, 0, -0.08, 0.04, 0.025, _ink);
    for (final sx in [-1.0, 1.0]) {
      c.drawLine(
        Offset(sx * 0.1, -0.33),
        Offset(sx * 0.18, -0.2),
        _stroke(spec.c2, 0.03),
      );
    }
  }

  void _moon(Canvas c) {
    c.drawCircle(Offset.zero, 0.8, _f(spec.c1));
    c.drawPath(
      Path()..addArc(
        Rect.fromCircle(center: const Offset(0.28, 0), radius: 0.82),
        0,
        2 * math.pi,
      ),
      _f(spec.c1.withValues(alpha: 0.0)),
    );
    for (final o in const [
      Offset(-0.45, -0.4),
      Offset(0.4, -0.45),
      Offset(0.5, 0.35),
    ]) {
      _oval(c, o.dx, o.dy, 0.12, 0.1, spec.c2.withValues(alpha: 0.6));
    }
    _eyes(c, 0, -0.08, 0.28, 0.07);
    _cheeks(c, 0, 0.1, 0.42, 0.09);
    _smile(c, 0, 0.12, 0.13);
    _starShape(
      c,
      const Offset(0.82, -0.75),
      0.1,
      const Color(0xFFFFE680),
      rot: calm ? 0 : _tt,
    );
  }

  void _planet(Canvas c) {
    final ring = Rect.fromCenter(center: Offset.zero, width: 2.0, height: 0.55);
    c.save();
    c.rotate(-0.3);
    c.drawArc(ring, math.pi, math.pi, false, _stroke(spec.c3, 0.12));
    c.restore();
    c.drawCircle(Offset.zero, 0.62, _f(spec.c1));
    c.save();
    c.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.62)),
    );
    for (final dy in [-0.4, 0.3, 0.52]) {
      c.drawRect(
        Rect.fromLTWH(-0.7, dy, 1.4, 0.1),
        _f(spec.c2.withValues(alpha: 0.7)),
      );
    }
    c.restore();
    c.save();
    c.rotate(-0.3);
    c.drawArc(ring, 0, math.pi, false, _stroke(spec.c3, 0.12));
    c.restore();
    _eyes(c, 0, -0.08, 0.22, 0.07);
    _cheeks(c, 0, 0.1, 0.35, 0.08);
    _smile(c, 0, 0.12, 0.11);
  }

  void _star(Canvas c) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 0.92 : 0.5;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(math.cos(a) * r, math.sin(a) * r + 0.05);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    c.drawPath(path, _f(spec.c1));
    c.drawPath(path, _stroke(_shade(spec.c1, -0.1), 0.06));
    _eyes(c, 0, 0.05, 0.17, 0.06);
    _cheeks(c, 0, 0.22, 0.27, 0.07);
    _smile(c, 0, 0.22, 0.09);
  }

  // ---------- Natur ----------
  void _sun(Canvas c) {
    final spin = calm ? 0.0 : _tt * 0.6;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + spin;
      final p = Path()
        ..moveTo(math.cos(a - 0.12) * 0.62, math.sin(a - 0.12) * 0.62)
        ..lineTo(math.cos(a) * 0.95, math.sin(a) * 0.95)
        ..lineTo(math.cos(a + 0.12) * 0.62, math.sin(a + 0.12) * 0.62)
        ..close();
      c.drawPath(p, _f(spec.c2));
    }
    c.drawCircle(Offset.zero, 0.62, _f(spec.c1));
    _eyes(c, 0, -0.08, 0.24, 0.07);
    _cheeks(c, 0, 0.1, 0.38, 0.09);
    _smile(c, 0, 0.12, 0.13);
  }

  void _flower(Canvas c) {
    c.drawLine(
      const Offset(0, 0.2),
      const Offset(0, 0.95),
      _stroke(spec.c3, 0.1),
    );
    _oval(c, -0.25, 0.65, 0.2, 0.09, spec.c3);
    _oval(c, 0.25, 0.55, 0.2, 0.09, spec.c3);
    final sway = calm ? 0.0 : math.sin(_tt * 2) * 0.05;
    c.save();
    c.translate(0, 0.15);
    c.rotate(sway);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      _oval(
        c,
        math.cos(a) * 0.5,
        math.sin(a) * 0.5 - 0.15,
        0.24,
        0.24,
        spec.c1,
      );
    }
    _oval(c, 0, -0.15, 0.4, 0.4, spec.c2);
    _eyes(c, 0, -0.2, 0.15, 0.055);
    _cheeks(c, 0, -0.07, 0.25, 0.06);
    _smile(c, 0, -0.06, 0.08);
    c.restore();
  }

  void _tree(Canvas c) {
    final sway = calm ? 0.0 : math.sin(_tt * 1.6) * 0.03;
    c.drawPath(
      Path()
        ..moveTo(-0.17, 0.95)
        ..lineTo(-0.1, 0.1)
        ..lineTo(0.1, 0.1)
        ..lineTo(0.17, 0.95)
        ..close(),
      _f(spec.c3),
    );
    c.save();
    c.rotate(sway);
    for (final o in const [
      Offset(-0.4, 0.0),
      Offset(0.4, 0.0),
      Offset(0, -0.45),
      Offset(-0.25, -0.35),
      Offset(0.25, -0.35),
    ]) {
      _oval(c, o.dx, o.dy, 0.4, 0.38, spec.c1);
    }
    _oval(c, 0, -0.15, 0.5, 0.42, spec.c1);
    _oval(c, -0.2, -0.35, 0.18, 0.12, spec.c2.withValues(alpha: 0.6));
    _eyes(c, 0, -0.15, 0.2, 0.065);
    _cheeks(c, 0, 0.02, 0.32, 0.07);
    _smile(c, 0, 0.02, 0.1);
    c.restore();
    for (final o in const [
      Offset(-0.35, 0.1),
      Offset(0.4, -0.05),
      Offset(0.1, -0.6),
    ]) {
      c.drawCircle(o, 0.05, _f(const Color(0xFFE5574B)));
    }
  }

  void _mushroom(Canvas c) {
    c.drawPath(
      Path()
        ..moveTo(-0.28, 0.95)
        ..quadraticBezierTo(-0.2, 0.2, -0.25, -0.05)
        ..lineTo(0.25, -0.05)
        ..quadraticBezierTo(0.2, 0.2, 0.28, 0.95)
        ..close(),
      _f(spec.c2),
    );
    c.drawArc(
      Rect.fromCenter(center: const Offset(0, -0.05), width: 1.8, height: 1.5),
      math.pi,
      math.pi,
      true,
      _f(spec.c1),
    );
    for (final o in const [
      Offset(-0.4, -0.4),
      Offset(0.05, -0.62),
      Offset(0.45, -0.35),
      Offset(-0.1, -0.3),
    ]) {
      _oval(c, o.dx, o.dy, 0.11, 0.09, spec.c2);
    }
    _eyes(c, 0, 0.2, 0.12, 0.055);
    _cheeks(c, 0, 0.32, 0.2, 0.05);
    _smile(c, 0, 0.33, 0.07);
  }

  // ---------- Jahreszeiten ----------
  void _snowman(Canvas c) {
    _oval(c, 0, 0.55, 0.52, 0.45, spec.c1);
    _oval(c, 0, 0.0, 0.4, 0.38, spec.c1);
    _oval(c, 0, -0.5, 0.33, 0.31, spec.c1);
    c.drawPath(
      Path()..addOval(
        Rect.fromCenter(
          center: const Offset(0, -0.5),
          width: 0.66,
          height: 0.62,
        ),
      ),
      _stroke(const Color(0xFFD5E6F5), 0.02),
    );
    // Mütze
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.28, -1.0, 0.56, 0.35),
        const Radius.circular(0.08),
      ),
      _f(spec.c2),
    );
    c.drawRect(
      const Rect.fromLTWH(-0.4, -0.72, 0.8, 0.08),
      _f(_shade(spec.c2, -0.1)),
    );
    // Schal
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.34, -0.25, 0.68, 0.12),
        const Radius.circular(0.06),
      ),
      _f(spec.c2),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.15, -0.2, 0.12, 0.3),
        const Radius.circular(0.05),
      ),
      _f(spec.c2),
    );
    _eyes(c, 0, -0.52, 0.12, 0.045);
    c.drawPath(
      Path()
        ..moveTo(0, -0.45)
        ..lineTo(0.22, -0.4)
        ..lineTo(0, -0.37)
        ..close(),
      _f(spec.c3),
    );
    for (final dy in [-0.05, 0.12]) {
      c.drawCircle(Offset(0, dy + 0.15), 0.035, _f(_ink));
    }
    c.drawLine(
      const Offset(-0.38, 0.0),
      const Offset(-0.75, -0.2),
      _stroke(const Color(0xFF6B4423), 0.04),
    );
    c.drawLine(
      const Offset(0.38, 0.0),
      const Offset(0.75, -0.2),
      _stroke(const Color(0xFF6B4423), 0.04),
    );
  }

  void _pumpkin(Canvas c) {
    for (final dx in [-0.4, 0.4]) {
      _oval(c, dx, 0.3, 0.38, 0.6, _shade(spec.c1, -0.06));
    }
    _oval(c, 0, 0.3, 0.42, 0.64, spec.c1);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.07, -0.55, 0.14, 0.22),
        const Radius.circular(0.05),
      ),
      _f(spec.c2),
    );
    _eyes(c, 0, 0.15, 0.25, 0.07);
    _cheeks(c, 0, 0.38, 0.42, 0.08);
    _smile(c, 0, 0.4, 0.14);
  }

  void _egg(Canvas c) {
    final path = Path()
      ..moveTo(0, -0.9)
      ..cubicTo(0.75, -0.9, 0.85, 0.9, 0, 0.92)
      ..cubicTo(-0.85, 0.9, -0.75, -0.9, 0, -0.9)
      ..close();
    c.drawPath(path, _f(spec.c1));
    c.save();
    c.clipPath(path);
    // Zickzack-Band und Punkte
    final z = Path()..moveTo(-1, 0.25);
    for (var i = 0; i < 8; i++) {
      z.lineTo(-1 + i * 0.28 + 0.14, i.isEven ? 0.05 : 0.25);
    }
    z.lineTo(1.2, 0.5);
    z.lineTo(-1.1, 0.5);
    z.close();
    c.drawPath(z, _f(spec.c2));
    for (final o in const [
      Offset(-0.3, -0.5),
      Offset(0.3, -0.62),
      Offset(0.0, -0.3),
      Offset(-0.1, 0.7),
      Offset(0.35, 0.72),
    ]) {
      c.drawCircle(o, 0.06, _f(spec.c3));
    }
    c.restore();
    _eyes(c, 0, -0.1, 0.2, 0.06);
    _cheeks(c, 0, 0.05, 0.33, 0.07);
    _smile(c, 0, 0.04, 0.09);
  }

  void _xmas(Canvas c) {
    c.drawRect(
      const Rect.fromLTWH(-0.1, 0.8, 0.2, 0.15),
      _f(const Color(0xFF8A5A2B)),
    );
    for (var i = 0; i < 3; i++) {
      final top = -0.7 + i * 0.45;
      final w = 0.45 + i * 0.2;
      c.drawPath(
        Path()
          ..moveTo(0, top)
          ..lineTo(w, top + 0.6)
          ..lineTo(-w, top + 0.6)
          ..close(),
        _f(_shade(spec.c1, i * 0.03)),
      );
    }
    final twinkle = calm ? 1.0 : 0.6 + 0.4 * math.sin(_tt * 4);
    _starShape(
      c,
      const Offset(0, -0.85),
      0.14,
      Color.lerp(_w, spec.c2, twinkle)!,
    );
    for (final o in const [
      Offset(-0.35, 0.65),
      Offset(0.4, 0.5),
      Offset(-0.2, 0.12),
      Offset(0.25, -0.15),
      Offset(0.0, -0.45),
    ]) {
      c.drawCircle(o, 0.06, _f(spec.c3));
    }
    _eyes(c, 0, 0.3, 0.14, 0.05);
    _smile(c, 0, 0.45, 0.08);
  }

  // ---------- Weitere Figuren ----------
  void _antlers(Canvas c, CritterStyle s, double hy, double hr) {
    for (final sx in [-1.0, 1.0]) {
      final p = Path()
        ..moveTo(sx * 0.14, hy - hr * 0.9)
        ..lineTo(sx * 0.22, hy - hr * 1.55)
        ..moveTo(sx * 0.19, hy - hr * 1.2)
        ..lineTo(sx * 0.4, hy - hr * 1.45)
        ..moveTo(sx * 0.21, hy - hr * 1.42)
        ..lineTo(sx * 0.1, hy - hr * 1.75);
      c.drawPath(p, _stroke(const Color(0xFF8A5A2B), 0.05));
    }
  }

  void _jellyfish(Canvas c) {
    for (var i = 0; i < 5; i++) {
      final x = -0.4 + i * 0.2;
      final w = calm ? 0.0 : math.sin(_tt * 3 + i) * 0.07;
      final p = Path()
        ..moveTo(x, 0.2)
        ..quadraticBezierTo(x + w, 0.5, x - w, 0.7)
        ..quadraticBezierTo(x + w * 1.5, 0.85, x, 0.97);
      c.drawPath(p, _stroke(spec.c3.withValues(alpha: 0.85), 0.06));
    }
    final dome = Path()
      ..moveTo(-0.7, 0.25)
      ..quadraticBezierTo(-0.7, -0.85, 0, -0.85)
      ..quadraticBezierTo(0.7, -0.85, 0.7, 0.25)
      ..quadraticBezierTo(0.45, 0.14, 0.23, 0.25)
      ..quadraticBezierTo(0, 0.14, -0.23, 0.25)
      ..quadraticBezierTo(-0.45, 0.14, -0.7, 0.25)
      ..close();
    c.drawPath(dome, _f(spec.c1));
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-0.25, -0.5),
        width: 0.3,
        height: 0.14,
      ),
      _f(Colors.white.withValues(alpha: 0.45)),
    );
    for (final o in const [
      Offset(0.35, -0.45),
      Offset(0.0, -0.7),
      Offset(-0.45, -0.2),
    ]) {
      c.drawCircle(o, 0.05, _f(spec.c2));
    }
    _eyes(c, 0, -0.2, 0.26, 0.07);
    _cheeks(c, 0, -0.05, 0.42, 0.08);
    _smile(c, 0, -0.04, 0.1);
  }

  void _astronaut(Canvas c) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.62, -0.05, 0.28, 0.65),
        const Radius.circular(0.1),
      ),
      _f(spec.c2),
    );
    for (final sx in [-1.0, 1.0]) {
      _oval(c, sx * 0.58, 0.3, 0.13, 0.25, _shade(spec.c1, -0.05));
      _oval(c, sx * 0.22, 0.88, 0.17, 0.09, _shade(spec.c1, -0.1));
    }
    _oval(c, 0, 0.4, 0.5, 0.5, spec.c1);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.2, 0.28, 0.4, 0.26),
        const Radius.circular(0.06),
      ),
      _f(spec.c2),
    );
    c.drawCircle(const Offset(-0.1, 0.41), 0.04, _f(const Color(0xFF58B368)));
    c.drawCircle(const Offset(0.02, 0.41), 0.04, _f(spec.c3));
    c.drawCircle(const Offset(0, -0.3), 0.55, _f(spec.c1));
    c.drawCircle(
      const Offset(0, -0.3),
      0.55,
      _stroke(const Color(0xFFD5DAE6), 0.04),
    );
    final visor = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(0, -0.28),
        width: 0.78,
        height: 0.58,
      ),
      const Radius.circular(0.28),
    );
    c.drawRRect(visor, _f(const Color(0xFF2A3A6B)));
    c.drawRRect(visor.deflate(0.04), _f(const Color(0xFF3F5BA0)));
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(-0.22, -0.43),
        width: 0.2,
        height: 0.08,
      ),
      _f(Colors.white.withValues(alpha: 0.5)),
    );
    _eyes(c, 0, -0.27, 0.17, 0.06);
    _smile(c, 0, -0.14, 0.08);
  }

  void _cloud(Canvas c) {
    final drift = calm ? 0.0 : math.sin(_tt * 1.2) * 0.03;
    c.save();
    c.translate(drift, 0);
    final shade = _f(spec.c2);
    for (final o in const [
      Offset(-0.45, 0.25),
      Offset(0.45, 0.25),
      Offset(-0.15, -0.1),
      Offset(0.28, -0.05),
    ]) {
      c.drawCircle(o + const Offset(0, 0.04), 0.4, shade);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.85, 0.2, 1.7, 0.5),
        const Radius.circular(0.25),
      ),
      shade,
    );
    for (final o in const [
      Offset(-0.45, 0.25),
      Offset(0.45, 0.25),
      Offset(-0.15, -0.1),
      Offset(0.28, -0.05),
    ]) {
      c.drawCircle(o, 0.4, _f(spec.c1));
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.85, 0.15, 1.7, 0.5),
        const Radius.circular(0.25),
      ),
      _f(spec.c1),
    );
    _eyes(c, 0, 0.12, 0.2, 0.065);
    _cheeks(c, 0, 0.27, 0.32, 0.07);
    _smile(c, 0, 0.28, 0.09);
    c.restore();
    if (!calm) {
      for (var i = 0; i < 3; i++) {
        final k = ((_tt * 0.9) + i / 3) % 1;
        _oval(
          c,
          -0.3 + i * 0.3,
          0.72 + k * 0.22,
          0.03,
          0.05,
          spec.c3.withValues(alpha: 1 - k),
        );
      }
    }
  }

  void _cactus(Canvas c) {
    c.drawPath(
      Path()
        ..moveTo(-0.38, 0.62)
        ..lineTo(0.38, 0.62)
        ..lineTo(0.3, 0.97)
        ..lineTo(-0.3, 0.97)
        ..close(),
      _f(const Color(0xFFE08A4C)),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.44, 0.56, 0.88, 0.12),
        const Radius.circular(0.05),
      ),
      _f(const Color(0xFFC96F32)),
    );
    for (final sx in [-1.0, 1.0]) {
      final arm = Path()
        ..moveTo(sx * 0.2, 0.3)
        ..lineTo(sx * 0.55, 0.3)
        ..lineTo(sx * 0.55, -0.1);
      c.drawPath(arm, _stroke(spec.c1, 0.2));
    }
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.3, -0.62, 0.6, 1.25),
        const Radius.circular(0.3),
      ),
      _f(spec.c1),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.3, -0.62, 0.18, 1.2),
        const Radius.circular(0.1),
      ),
      _f(spec.c2.withValues(alpha: 0.5)),
    );
    for (final o in const [
      Offset(-0.2, 0.2),
      Offset(0.22, 0.05),
      Offset(-0.18, 0.45),
      Offset(0.2, 0.4),
      Offset(0.45, -0.2),
      Offset(-0.5, -0.05),
    ]) {
      c.drawLine(o, o + const Offset(0.0, -0.04), _stroke(Colors.white, 0.02));
    }
    for (final a in [0.0, 1.2, 2.4, 3.6, 4.8]) {
      _oval(
        c,
        math.cos(a) * 0.1,
        -0.7 + math.sin(a) * 0.06,
        0.07,
        0.07,
        spec.c3,
      );
    }
    c.drawCircle(const Offset(0, -0.7), 0.05, _f(const Color(0xFFFFD84D)));
    _eyes(c, 0, -0.2, 0.12, 0.055);
    _cheeks(c, 0, -0.07, 0.2, 0.05);
    _smile(c, 0, -0.06, 0.07);
  }

  void _ghost(Canvas c) {
    final f = calm ? 0.0 : math.sin(_tt * 2.5) * 0.05;
    c.save();
    c.translate(0, f);
    final body = Path()
      ..moveTo(-0.55, 0.85)
      ..lineTo(-0.55, -0.1)
      ..quadraticBezierTo(-0.55, -0.85, 0, -0.85)
      ..quadraticBezierTo(0.55, -0.85, 0.55, -0.1)
      ..lineTo(0.55, 0.85)
      ..quadraticBezierTo(0.4, 0.7, 0.27, 0.85)
      ..quadraticBezierTo(0.13, 1.0, 0, 0.85)
      ..quadraticBezierTo(-0.13, 0.7, -0.27, 0.85)
      ..quadraticBezierTo(-0.4, 1.0, -0.55, 0.85)
      ..close();
    c.drawPath(body, _f(spec.c2));
    c.save();
    c.translate(0, -0.03);
    c.drawPath(body, _f(spec.c1));
    c.restore();
    for (final sx in [-1.0, 1.0]) {
      _oval(c, sx * 0.62, 0.25, 0.13, 0.2, spec.c1);
    }
    _eyes(c, 0, -0.25, 0.2, 0.08);
    _cheeks(c, 0, -0.08, 0.34, 0.08);
    _smile(c, 0, -0.06, 0.1);
    c.restore();
  }

  void _ladybug(Canvas c) {
    for (final sx in [-1.0, 1.0]) {
      c.drawLine(
        Offset(sx * 0.25, -0.6),
        Offset(sx * 0.38, -0.88),
        _stroke(spec.c2, 0.04),
      );
      c.drawCircle(Offset(sx * 0.38, -0.9), 0.05, _f(spec.c2));
      for (final dy in [0.1, 0.35, 0.6]) {
        c.drawLine(
          Offset(sx * 0.5, dy),
          Offset(sx * 0.78, dy + 0.1),
          _stroke(spec.c2, 0.05),
        );
      }
    }
    c.drawCircle(const Offset(0, 0.3), 0.66, _f(spec.c1));
    c.drawLine(
      const Offset(0, -0.35),
      const Offset(0, 0.96),
      _stroke(spec.c2, 0.04),
    );
    for (final o in const [
      Offset(-0.33, 0.1),
      Offset(0.33, 0.1),
      Offset(-0.38, 0.52),
      Offset(0.38, 0.52),
      Offset(-0.12, 0.75),
      Offset(0.12, 0.75),
    ]) {
      c.drawCircle(o, 0.1, _f(spec.c2));
    }
    c.drawOval(
      Rect.fromCenter(
        center: const Offset(0, -0.35),
        width: 0.92,
        height: 0.62,
      ),
      _f(spec.c2),
    );
    for (final sx in [-1.0, 1.0]) {
      _oval(c, sx * 0.22, -0.4, 0.13, 0.15, Colors.white);
      c.drawCircle(Offset(sx * 0.22 + 0.02, -0.39), 0.065, _f(_ink));
      c.drawCircle(Offset(sx * 0.22 + 0.04, -0.42), 0.022, _f(Colors.white));
    }
    final smile = Path()
      ..moveTo(-0.1, -0.2)
      ..quadraticBezierTo(0, -0.12, 0.1, -0.2);
    c.drawPath(smile, _stroke(Colors.white, 0.03));
  }

  @override
  bool shouldRepaint(CharacterPainter old) =>
      old.t != t || old.mood != mood || old.spec != spec || old.calm != calm;
}

/// Bequemes Widget für Vorschauen (z.B. Auswahlraster).
class CharacterView extends StatelessWidget {
  const CharacterView({
    super.key,
    required this.spec,
    this.t = 0,
    this.mood = Mood.idle,
    this.calm = false,
    this.shadow = false,
  });
  final CharacterSpec spec;
  final double t;
  final Mood mood;
  final bool calm;
  final bool shadow;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: CharacterPainter(
      spec,
      t: t,
      mood: mood,
      calm: calm,
      shadow: shadow,
    ),
    size: Size.infinite,
  );
}
