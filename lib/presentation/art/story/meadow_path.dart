import 'dart:math' as math;
import 'dart:ui';

/// Der gemalte Weg der Blumenwiese in **Bildkoordinaten** des Referenzbildes (1199×1312).
/// Mira läuft entlang dieser Mittellinie; die Sternsteine sind die Etappen.
class MeadowPath {
  MeadowPath._() {
    // Catmull-Rom-Abtastung der Kontrollpunkte
    final pts = control;
    final out = <Offset>[];
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(i - 1, 0)];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[math.min(i + 2, pts.length - 1)];
      for (var k = 0; k < 16; k++) {
        final t = k / 16;
        final t2 = t * t, t3 = t2 * t;
        out.add(
          Offset(
            0.5 *
                ((2 * p1.dx) +
                    (-p0.dx + p2.dx) * t +
                    (2 * p0.dx - 5 * p1.dx + 4 * p2.dx - p3.dx) * t2 +
                    (-p0.dx + 3 * p1.dx - 3 * p2.dx + p3.dx) * t3),
            0.5 *
                ((2 * p1.dy) +
                    (-p0.dy + p2.dy) * t +
                    (2 * p0.dy - 5 * p1.dy + 4 * p2.dy - p3.dy) * t2 +
                    (-p0.dy + 3 * p1.dy - 3 * p2.dy + p3.dy) * t3),
          ),
        );
      }
    }
    out.add(pts.last);
    samples = out;
    final cum = <double>[0];
    for (var i = 1; i < out.length; i++) {
      cum.add(cum.last + (out[i] - out[i - 1]).distance);
    }
    final total = cum.last;
    arc = [for (final c in cum) c / total];
    // Etappen: Parameter des nächstgelegenen Wegpunkts je Sternstein
    stationU = [
      for (final s in stones)
        () {
          var best = 0, bd = double.infinity;
          for (var i = 0; i < out.length; i++) {
            final d = (out[i] - s).distanceSquared;
            if (d < bd) {
              bd = d;
              best = i;
            }
          }
          return arc[best];
        }(),
    ];
  }

  static final MeadowPath instance = MeadowPath._();

  static const imageSize = Size(1199, 1312);

  /// Mittellinie des Weges von der Startstelle (unten links) bis zur Haustür.
  static const control = <Offset>[
    Offset(265, 790),
    Offset(330, 790),
    Offset(420, 775),
    Offset(500, 748),
    Offset(560, 718),
    Offset(572, 684),
    Offset(512, 654),
    Offset(462, 632),
    Offset(448, 612),
    Offset(540, 598),
    Offset(650, 602),
    Offset(808, 594),
    Offset(920, 586),
    Offset(1002, 566),
    Offset(1042, 534),
    Offset(1048, 508),
    Offset(1010, 478),
    Offset(950, 470),
    Offset(960, 452),
    Offset(1000, 440),
    Offset(1026, 436),
    Offset(1030, 418),
  ];

  /// Mittelpunkte der gemalten Sternsteine im Bild (Reihenfolge: Start → Ziel).
  static const stones = <Offset>[
    Offset(145, 775),
    Offset(497, 744),
    Offset(448, 611),
    Offset(808, 593),
    Offset(1010, 543),
    Offset(945, 477),
    Offset(1025, 438),
  ];

  late final List<Offset> samples;
  late final List<double> arc; // normierte Bogenlänge je Abtastpunkt (0..1)
  late final List<double> stationU;

  /// Punkt auf dem Weg bei Fortschritt [u] ∈ [0,1] (nach Bogenlänge).
  Offset at(double u) {
    final x = u.clamp(0.0, 1.0);
    var lo = 0, hi = arc.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (arc[mid] <= x) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = arc[hi] - arc[lo];
    final f = span <= 0 ? 0.0 : (x - arc[lo]) / span;
    return Offset.lerp(samples[lo], samples[hi], f)!;
  }
}
