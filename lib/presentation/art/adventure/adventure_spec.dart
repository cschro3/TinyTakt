import 'dart:math' as math;
import 'dart:ui';

/// Geometrie einer Abenteuer-Szene in Bildschirmkoordinaten.
///
/// [box] ist das quadratische Feld, in dem der Weg liegt (Pfad-Koordinaten 0…1 beziehen sich darauf);
/// Hintergründe dürfen den ganzen Bildschirm [size] füllen.
class AdvFrame {
  AdvFrame(this.size, this.box, List<Offset> control) {
    final pts = <Offset>[];
    final c = [for (final o in control) p(o.dx, o.dy)];
    for (var i = 0; i < c.length - 1; i++) {
      final p0 = c[math.max(i - 1, 0)], p1 = c[i], p2 = c[i + 1];
      final p3 = c[math.min(i + 2, c.length - 1)];
      for (var k = 0; k < 18; k++) {
        final t = k / 18, t2 = t * t, t3 = t2 * t;
        double f(double a, double b, double c2, double d) =>
            0.5 *
            ((2 * b) +
                (-a + c2) * t +
                (2 * a - 5 * b + 4 * c2 - d) * t2 +
                (-a + 3 * b - 3 * c2 + d) * t3);
        pts.add(
          Offset(f(p0.dx, p1.dx, p2.dx, p3.dx), f(p0.dy, p1.dy, p2.dy, p3.dy)),
        );
      }
    }
    pts.add(c.last);
    samples = pts;
    final cum = <double>[0];
    for (var i = 1; i < pts.length; i++) {
      cum.add(cum.last + (pts[i] - pts[i - 1]).distance);
    }
    arc = [for (final v in cum) v / cum.last];
  }

  final Size size;
  final Rect box;
  late final List<Offset> samples;
  late final List<double> arc;

  double get s => box.width;
  Offset p(double x, double y) =>
      Offset(box.left + x * box.width, box.top + y * box.height);

  /// Punkt auf dem Weg bei Fortschritt [u] (0…1, nach Weglänge).
  Offset at(double u) {
    u = u.clamp(0.0, 1.0);
    var lo = 0, hi = arc.length - 1;
    while (hi - lo > 1) {
      final mid = (lo + hi) >> 1;
      if (arc[mid] <= u) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    final span = arc[hi] - arc[lo];
    final k = span <= 0 ? 0.0 : (u - arc[lo]) / span;
    return Offset.lerp(samples[lo], samples[hi], k)!;
  }

  /// Tiefe 0 (hinten/oben) … 1 (vorn/unten) einer Bildschirmposition im Feld.
  double depth(Offset o) => ((o.dy - box.top) / box.height).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is AdvFrame && other.size == size && other.box == box;
  @override
  int get hashCode => Object.hash(size, box);
}

typedef AdvPaint = void Function(Canvas c, AdvFrame f);
typedef AdvAmbient = void Function(
  Canvas c,
  AdvFrame f,
  double t,
  int count,
  bool calm,
);
typedef AdvMarker = void Function(
  Canvas c,
  Offset pos,
  double s,
  double lit,
  double t,
);

/// Beschreibt ein Abenteuer vollständig: Landschaft, Weg, Etappen, Ziel, Ambiente.
/// Neue Welten = neuer [AdventureWorldSpec] + Eintrag in `adventureWorlds` – kein Screen ändert sich.
class AdventureWorldSpec {
  const AdventureWorldSpec({
    required this.id,
    required this.titleDe,
    required this.titleEn,
    required this.goalDe,
    required this.goalEn,
    required this.control,
    required this.stations,
    required this.scaleFar,
    required this.scaleNear,
    required this.pathFar,
    required this.pathNear,
    required this.pathFill,
    required this.pathEdge,
    required this.paintBack,
    required this.paintAmbient,
    required this.paintStation,
    required this.paintGoalGlow,
    this.paintFront,
    this.floating = false,
    this.bubble = false,
    this.barColors = const [Color(0xFF7B3FE0), Color(0xFFB97BFF)],
  });

  final String id, titleDe, titleEn, goalDe, goalEn;

  /// Wegpunkte im Feld (0…1), vom Start zum Ziel.
  final List<Offset> control;

  /// Etappen als Wegstrecken-Anteil (erster = Start 0, letzter = Ziel 1).
  final List<double> stations;

  /// Figurengröße relativ zum Feld bei Tiefe 0 / 1.
  final double scaleFar, scaleNear;

  /// Wegbreite relativ zum Feld bei Tiefe 0 / 1.
  final double pathFar, pathNear;
  final Color pathFill, pathEdge;

  /// Statische Ebene (gebacken): Himmel/Landschaft/Weg/Ziel.
  final AdvPaint paintBack;

  /// Statische Vordergrund-Ebene (optional, gebacken).
  final AdvPaint? paintFront;

  /// Bewegte Ebene (Partikel, Funkeln, Wellen).
  final AdvAmbient paintAmbient;

  /// Etappen-Markierung; [lit] 0…1 (erreicht).
  final AdvMarker paintStation;

  /// Leuchten des Ziels; [lit] 0…1.
  final AdvMarker paintGoalGlow;

  /// Figur schwebt (Weltraum, Wolken) bzw. steckt in einer Blase (Weltraum, Unterwasser).
  final bool floating, bubble;
  final List<Color> barColors;
}
