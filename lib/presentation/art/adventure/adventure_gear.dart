import 'dart:math' as math;
import 'dart:ui';

import '../../../domain/catalog.dart' show Archetype, CharacterSpec;

/// Abenteuer-Ausrüstung: kleine, skalierbare Teile (hinten/vorn), die je Welt automatisch über JEDE
/// Figur mit Kopf gelegt werden – ohne pro Kombination eigene Bilder. Sie zeichnen im Quadrat der
/// Figur (Seitenlänge `s`; Kopfmitte ≈ (0.5, 0.36), Kopfradius ≈ 0.27, Hals ≈ y 0.58).
///
/// Die Ausrüstung ist programmatisch gemalt (Fallback, keine Illustration). Figuren ohne Kopf
/// (Fahrzeuge, Himmelskörper, Pflanzen …) bekommen keine Ausrüstung ([gearFits]).
class AdventureGear {
  const AdventureGear(
    this.id,
    this.nameDe,
    this.nameEn,
    this.itemsDe,
    this.itemsEn,
    this.back,
    this.front,
  );
  final String id, nameDe, nameEn, itemsDe, itemsEn;
  final void Function(Canvas c, double s)? back;
  final void Function(Canvas c, double s)? front;
}

const _headLike = {
  Archetype.critter,
  Archetype.bird,
  Archetype.fluffy,
  Archetype.dino,
  Archetype.dragon,
  Archetype.robot,
  Archetype.monster,
  Archetype.astronaut,
  Archetype.frog,
  Archetype.fish,
  Archetype.whale,
  Archetype.octopus,
  Archetype.turtle,
  Archetype.crab,
  Archetype.ghost,
  Archetype.ladybug,
  Archetype.bee,
  Archetype.butterfly,
  Archetype.snail,
};

/// Trägt diese Figur Ausrüstung? (Kopf vorhanden)
bool gearFits(CharacterSpec spec) => _headLike.contains(spec.archetype);

AdventureGear? gearForWorld(String worldId) => adventureGear[worldId];

const _head = Offset(0.5, 0.36);

Paint _f(Color c) => Paint()..color = c;
Paint _s(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..color = c;

Shader _lin(Offset a, Offset b, List<Color> cols) => Gradient.linear(
  a,
  b,
  cols,
  [for (var i = 0; i < cols.length; i++) i / (cols.length - 1)],
);

void _tank(
  Canvas c,
  double s,
  double cx,
  double cy,
  double w,
  double h,
  Color body,
  Color band,
) {
  final r = Rect.fromCenter(
    center: Offset(cx * s, cy * s),
    width: w * s,
    height: h * s,
  );
  c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(w * s * 0.45)),
    Paint()
      ..shader = _lin(r.centerLeft, r.centerRight, [
        Color.lerp(body, const Color(0xFFFFFFFF), 0.45)!,
        body,
        Color.lerp(body, const Color(0xFF000000), 0.25)!,
      ]),
  );
  c.drawRect(
    Rect.fromCenter(
      center: Offset(cx * s, (cy - h * 0.18) * s),
      width: w * s,
      height: h * s * 0.1,
    ),
    _f(band),
  );
}

void _flower(Canvas c, Offset p, double r, Color petal) {
  for (var i = 0; i < 5; i++) {
    final a = i * math.pi * 2 / 5;
    c.drawCircle(
      p + Offset(math.cos(a), math.sin(a)) * r * 0.9,
      r * 0.62,
      _f(petal),
    );
  }
  c.drawCircle(p, r * 0.55, _f(const Color(0xFFFFD23F)));
}

final Map<String, AdventureGear> adventureGear = {
  for (final g in <AdventureGear>[
    AdventureGear(
      'space',
      'Raumanzug',
      'Space suit',
      'Helm, Sauerstofftanks, Kragen',
      'Helmet, oxygen tanks, collar',
      (c, s) {
        _tank(
          c,
          s,
          0.16,
          0.62,
          0.15,
          0.34,
          const Color(0xFFC8D2E8),
          const Color(0xFFFF8A3A),
        );
        _tank(
          c,
          s,
          0.84,
          0.62,
          0.15,
          0.34,
          const Color(0xFFC8D2E8),
          const Color(0xFFFF8A3A),
        );
      },
      (c, s) {
        final h = _head * s;
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.515 * s),
            width: 0.46 * s,
            height: 0.10 * s,
          ),
          Paint()
            ..shader = _lin(Offset(0, 0.465 * s), Offset(0, 0.565 * s), const [
              Color(0xFFF2F6FF),
              Color(0xFF9AA8C8),
            ]),
        );
        c.drawRect(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.52 * s),
            width: 0.44 * s,
            height: 0.022 * s,
          ),
          _f(const Color(0xFFFF8A3A)),
        );
        c.drawCircle(
          h,
          0.33 * s,
          Paint()
            ..shader = Gradient.radial(
              h.translate(-0.1 * s, -0.12 * s),
              0.45 * s,
              const [Color(0x40FFFFFF), Color(0x10CFE8FF)],
            ),
        );
        c.drawCircle(h, 0.33 * s, _s(const Color(0xCCFFFFFF), 0.022 * s));
        c.drawArc(
          Rect.fromCircle(center: h, radius: 0.27 * s),
          math.pi * 1.1,
          math.pi * 0.35,
          false,
          _s(const Color(0xDDFFFFFF), 0.026 * s),
        );
        c.drawCircle(
          h.translate(-0.17 * s, -0.17 * s),
          0.018 * s,
          _f(const Color(0xEEFFFFFF)),
        );
      },
    ),
    AdventureGear(
      'forest',
      'Entdeckerausrüstung',
      'Explorer kit',
      'Entdeckerhut, Rucksack',
      'Explorer hat, backpack',
      (c, s) {
        final r = Rect.fromLTWH(0.60 * s, 0.50 * s, 0.30 * s, 0.34 * s);
        c.drawRRect(
          RRect.fromRectAndRadius(r, Radius.circular(0.06 * s)),
          Paint()
            ..shader = _lin(r.topLeft, r.bottomRight, const [
              Color(0xFF5A9A4A),
              Color(0xFF2E6A3A),
            ]),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0.64 * s, 0.66 * s, 0.22 * s, 0.12 * s),
            Radius.circular(0.03 * s),
          ),
          _f(const Color(0xFF3E7A3A)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0.62 * s, 0.46 * s, 0.26 * s, 0.07 * s),
            Radius.circular(0.035 * s),
          ),
          _f(const Color(0xFFE8C468)),
        );
      },
      (c, s) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.155 * s),
            width: 0.66 * s,
            height: 0.13 * s,
          ),
          _f(const Color(0xFF8A5A2E)),
        );
        final crown = Rect.fromCenter(
          center: Offset(0.5 * s, 0.10 * s),
          width: 0.36 * s,
          height: 0.15 * s,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(crown, Radius.circular(0.07 * s)),
          Paint()
            ..shader = _lin(crown.topCenter, crown.bottomCenter, const [
              Color(0xFFB07A44),
              Color(0xFF8A5A2E),
            ]),
        );
        c.drawRect(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.145 * s),
            width: 0.36 * s,
            height: 0.03 * s,
          ),
          _f(const Color(0xFF3E7A3A)),
        );
      },
    ),
    AdventureGear(
      'underwater',
      'Taucherausrüstung',
      'Diving gear',
      'Tauchmaske, Schnorchel, Tank',
      'Dive mask, snorkel, tank',
      (c, s) {
        _tank(
          c,
          s,
          0.5,
          0.64,
          0.30,
          0.20,
          const Color(0xFFFFC83D),
          const Color(0xFF203050),
        );
      },
      (c, s) {
        final h = _head * s;
        c.drawLine(
          Offset(0.20 * s, 0.37 * s),
          Offset(0.80 * s, 0.37 * s),
          _s(const Color(0xFF203050), 0.03 * s),
        );
        for (final dx in const [-0.115, 0.115]) {
          final r = Rect.fromCenter(
            center: h.translate(dx * s, 0.01 * s),
            width: 0.22 * s,
            height: 0.17 * s,
          );
          c.drawOval(r, _f(const Color(0x4430C0E8)));
          c.drawOval(r, _s(const Color(0xFF14A8C8), 0.028 * s));
        }
        c.drawLine(
          Offset(0.5 * s, 0.355 * s),
          Offset(0.5 * s, 0.375 * s),
          _s(const Color(0xFF14A8C8), 0.03 * s),
        );
        final tube = Path()
          ..moveTo(0.82 * s, 0.38 * s)
          ..quadraticBezierTo(0.92 * s, 0.30 * s, 0.86 * s, 0.10 * s);
        c.drawPath(tube, _s(const Color(0xFFFF8A3A), 0.04 * s));
        c.drawCircle(
          Offset(0.86 * s, 0.10 * s),
          0.028 * s,
          _f(const Color(0xFFFFE08A)),
        );
      },
    ),
    AdventureGear(
      'winter',
      'Winterkleidung',
      'Winter wear',
      'Bommelmütze, Schal',
      'Pompom beanie, scarf',
      null,
      (c, s) {
        final dome = Rect.fromCenter(
          center: Offset(0.5 * s, 0.16 * s),
          width: 0.54 * s,
          height: 0.30 * s,
        );
        c.drawArc(
          dome,
          math.pi,
          math.pi,
          true,
          Paint()
            ..shader = _lin(dome.topCenter, dome.center, const [
              Color(0xFFFF6A5A),
              Color(0xFFD0384A),
            ]),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0.5 * s, 0.165 * s),
              width: 0.56 * s,
              height: 0.07 * s,
            ),
            Radius.circular(0.035 * s),
          ),
          _f(const Color(0xFFFFFFFF)),
        );
        c.drawCircle(
          Offset(0.5 * s, 0.0 * s + 0.03 * s),
          0.05 * s,
          _f(const Color(0xFFFFFFFF)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0.5 * s, 0.515 * s),
              width: 0.50 * s,
              height: 0.09 * s,
            ),
            Radius.circular(0.04 * s),
          ),
          _f(const Color(0xFF3AA0E8)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0.60 * s, 0.535 * s, 0.09 * s, 0.20 * s),
            Radius.circular(0.03 * s),
          ),
          _f(const Color(0xFF2A88D0)),
        );
        for (var i = 0; i < 4; i++) {
          c.drawRect(
            Rect.fromLTWH((0.28 + i * 0.12) * s, 0.50 * s, 0.04 * s, 0.03 * s),
            _f(const Color(0xFFFFFFFF)),
          );
        }
      },
    ),
    AdventureGear(
      'sunset',
      'Expeditionskleidung',
      'Expedition wear',
      'Entdeckerkappe, warmer Schal, Bündel',
      'Explorer cap, warm scarf, bedroll',
      (c, s) {
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0.60 * s, 0.50 * s, 0.30 * s, 0.14 * s),
            Radius.circular(0.07 * s),
          ),
          _f(const Color(0xFFC8683A)),
        );
        c.drawRect(
          Rect.fromLTWH(0.68 * s, 0.50 * s, 0.03 * s, 0.14 * s),
          _f(const Color(0xFF8A3A2A)),
        );
      },
      (c, s) {
        final dome = Rect.fromCenter(
          center: Offset(0.5 * s, 0.16 * s),
          width: 0.50 * s,
          height: 0.28 * s,
        );
        c.drawArc(
          dome,
          math.pi,
          math.pi,
          true,
          Paint()
            ..shader = _lin(dome.topCenter, dome.center, const [
              Color(0xFFD8B070),
              Color(0xFFB88A4A),
            ]),
        );
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.175 * s),
            width: 0.62 * s,
            height: 0.07 * s,
          ),
          _f(const Color(0xFF9A6A38)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0.5 * s, 0.515 * s),
              width: 0.48 * s,
              height: 0.08 * s,
            ),
            Radius.circular(0.04 * s),
          ),
          _f(const Color(0xFFFF8A4A)),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0.34 * s, 0.535 * s, 0.08 * s, 0.17 * s),
            Radius.circular(0.03 * s),
          ),
          _f(const Color(0xFFE8683A)),
        );
      },
    ),
    AdventureGear(
      'night',
      'Nachtreise-Ausrüstung',
      'Night-trip kit',
      'Schlafmütze mit Stern, Sternenumhang',
      'Star nightcap, star cape',
      (c, s) {
        final cape = Path()
          ..moveTo(0.28 * s, 0.56 * s)
          ..lineTo(0.72 * s, 0.56 * s)
          ..lineTo(0.84 * s, 0.92 * s)
          ..lineTo(0.16 * s, 0.92 * s)
          ..close();
        c.drawPath(
          cape,
          Paint()
            ..shader = _lin(Offset(0, 0.56 * s), Offset(0, 0.92 * s), const [
              Color(0xFF3A3A9A),
              Color(0xFF1A1A5A),
            ]),
        );
        for (final p in const [
          Offset(0.26, 0.78),
          Offset(0.74, 0.70),
          Offset(0.62, 0.86),
          Offset(0.38, 0.88),
        ]) {
          c.drawCircle(p * s, 0.012 * s, _f(const Color(0xFFFFE27A)));
        }
      },
      (c, s) {
        final cap = Path()
          ..moveTo(0.26 * s, 0.20 * s)
          ..quadraticBezierTo(0.40 * s, -0.04 * s, 0.70 * s, 0.02 * s)
          ..quadraticBezierTo(0.86 * s, 0.10 * s, 0.84 * s, 0.22 * s)
          ..quadraticBezierTo(0.5 * s, 0.14 * s, 0.26 * s, 0.20 * s)
          ..close();
        c.drawPath(
          cap,
          Paint()
            ..shader = _lin(Offset(0, 0), Offset(0, 0.22 * s), const [
              Color(0xFF5A5AD0),
              Color(0xFF2E2E9A),
            ]),
        );
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0.5 * s, 0.205 * s),
              width: 0.58 * s,
              height: 0.05 * s,
            ),
            Radius.circular(0.025 * s),
          ),
          _f(const Color(0xFFE8E4FF)),
        );
        c.drawCircle(
          Offset(0.84 * s, 0.22 * s),
          0.04 * s,
          _f(const Color(0xFFFFE27A)),
        );
        c.drawCircle(
          Offset(0.5 * s, 0.07 * s),
          0.014 * s,
          _f(const Color(0xFFFFE27A)),
        );
      },
    ),
    AdventureGear(
      'beach',
      'Strandausrüstung',
      'Beach kit',
      'Strohhut, Sonnenbrille',
      'Straw hat, sunglasses',
      null,
      (c, s) {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.16 * s),
            width: 0.76 * s,
            height: 0.14 * s,
          ),
          _f(const Color(0xFFE8C468)),
        );
        final crown = Rect.fromCenter(
          center: Offset(0.5 * s, 0.10 * s),
          width: 0.34 * s,
          height: 0.15 * s,
        );
        c.drawRRect(
          RRect.fromRectAndRadius(crown, Radius.circular(0.07 * s)),
          _f(const Color(0xFFF2D488)),
        );
        c.drawRect(
          Rect.fromCenter(
            center: Offset(0.5 * s, 0.14 * s),
            width: 0.34 * s,
            height: 0.03 * s,
          ),
          _f(const Color(0xFFFF6A5A)),
        );
        for (final dx in const [-0.11, 0.11]) {
          c.drawCircle(
            _head.translate(dx, 0.015) * s,
            0.085 * s,
            _f(const Color(0xDD203050)),
          );
          c.drawCircle(
            _head.translate(dx - 0.025, -0.01) * s,
            0.016 * s,
            _f(const Color(0x88FFFFFF)),
          );
        }
        c.drawLine(
          _head.translate(-0.03, 0.015) * s,
          _head.translate(0.03, 0.015) * s,
          _s(const Color(0xFF203050), 0.016 * s),
        );
      },
    ),
    AdventureGear(
      'sky',
      'Fliegerausrüstung',
      'Flying kit',
      'Pilotenbrille, kleine Flügel',
      'Pilot goggles, little wings',
      (c, s) {
        for (final side in [-1.0, 1.0]) {
          final w = Path()
            ..moveTo((0.5 + side * 0.18) * s, 0.55 * s)
            ..quadraticBezierTo(
              (0.5 + side * 0.52) * s,
              0.30 * s,
              (0.5 + side * 0.46) * s,
              0.62 * s,
            )
            ..quadraticBezierTo(
              (0.5 + side * 0.34) * s,
              0.58 * s,
              (0.5 + side * 0.18) * s,
              0.70 * s,
            )
            ..close();
          c.drawPath(
            w,
            Paint()
              ..shader = _lin(Offset(0, 0.3 * s), Offset(0, 0.7 * s), const [
                Color(0xFFFFFFFF),
                Color(0xFFCFE8FF),
              ]),
          );
        }
      },
      (c, s) {
        c.drawLine(
          Offset(0.22 * s, 0.22 * s),
          Offset(0.78 * s, 0.22 * s),
          _s(const Color(0xFF6A4A2E), 0.035 * s),
        );
        for (final dx in const [-0.1, 0.1]) {
          final p = Offset((0.5 + dx) * s, 0.22 * s);
          c.drawCircle(p, 0.075 * s, _f(const Color(0xFFB8E8FF)));
          c.drawCircle(p, 0.075 * s, _s(const Color(0xFFC8A04A), 0.026 * s));
          c.drawCircle(
            p.translate(-0.02 * s, -0.02 * s),
            0.014 * s,
            _f(const Color(0xCCFFFFFF)),
          );
        }
      },
    ),
    AdventureGear(
      'meadow',
      'Blumenwiesen-Schmuck',
      'Meadow finery',
      'Blumenkranz',
      'Flower crown',
      null,
      (c, s) {
        const cols = [
          Color(0xFFFF7AA8),
          Color(0xFFFFFFFF),
          Color(0xFFFFB84A),
          Color(0xFFB88AE8),
          Color(0xFFFF7AA8),
        ];
        for (var i = 0; i < 5; i++) {
          final a = math.pi * (1.12 + i * 0.19);
          final p = Offset(
            (0.5 + math.cos(a) * 0.27) * s,
            (0.30 + math.sin(a) * 0.20) * s,
          );
          _flower(c, p, 0.028 * s, cols[i]);
        }
      },
    ),
  ])
    g.id: g,
};
