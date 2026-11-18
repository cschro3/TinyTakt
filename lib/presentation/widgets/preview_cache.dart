import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import '../../app/perf_monitor.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Rendert Vorschauen (Figuren, Welten, Timer-Stile, Kachel-Rahmen) **einmal** in ein Bild in
/// Bildschirmauflösung und hält sie in einem LRU-Cache. Das Auswahlmenü zeichnet dann je Kachel nur
/// noch ein Bild statt jedes Mal die volle Vektorgrafik (81 Figuren mit Fell, Verläufen, Blur).
///
/// Optik: es wird derselbe Painter in derselben Größe mit derselben Pixeldichte gezeichnet;
/// das Bild ist nur ein Zwischenspeicher. Fällt `toImageSync` aus, zeichnet [CachedPreview] direkt.
class PreviewCache {
  PreviewCache._();
  static final PreviewCache instance = PreviewCache._();

  static const int maxEntries = 140;

  /// Obergrenze des Bildspeichers (RGBA) in MB; älteste Einträge fliegen zuerst raus.
  static const double maxMegabytes = 40;
  final LinkedHashMap<String, ui.Image> _map = LinkedHashMap();

  /// Anzahl gebackener Bilder (Tests/Messung).
  int get length => _map.length;
  int bakes = 0;

  double get megabytes => _map.values.fold<double>(
    0,
    (a, i) => a + i.width * i.height * 4 / 1048576,
  );

  static String _k(String key, Size logical, double dpr, Offset margin) =>
      '$key|${logical.width.toStringAsFixed(1)}x${logical.height.toStringAsFixed(1)}|${dpr.toStringAsFixed(2)}|${margin.dx.round()}';

  // Vorwärmen: unsichtbar gelayoutete Seiten melden ihre Vorschauen an; es wird höchstens eine
  // pro Bild gebacken, damit beim ersten Tab-Wechsel nichts mehr gezeichnet werden muss.
  final LinkedHashMap<String, void Function()> _queue = LinkedHashMap();
  bool _scheduled = false;

  /// Noch nicht gebackene, angemeldete Vorschauen.
  final ValueNotifier<int> pending = ValueNotifier(0);

  void enqueue(
    String key,
    Size logical,
    double dpr,
    void Function(Canvas, Size) draw, {
    Offset margin = Offset.zero,
  }) {
    _ensureListening();
    final k = _k(key, logical, dpr, margin);
    if (_map.containsKey(k) || _queue.containsKey(k)) return;
    _queue[k] = () => get(key, logical, dpr, draw, margin: margin);
    pending.value = _queue.length;
    _schedule();
  }

  // Vorwärmen nur bei Ruhe: keine Zeigerereignisse in den letzten 700 ms, damit Scrollen,
  // Tippen und Tab-Wechsel nie mit dem Backen zusammenfallen.
  final Stopwatch _since = Stopwatch()..start();
  int _lastPointerMs = -100000;
  bool _listening = false;
  Timer? _retry;

  void _onPointer(PointerEvent _) =>
      _lastPointerMs = _since.elapsedMilliseconds;

  /// Ab dem ersten Zugriff (Menü öffnen) merken, wann zuletzt bedient wurde.
  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
  }

  void _schedule() {
    if (_scheduled || _queue.isEmpty) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_queue.isEmpty) return;
      if (_since.elapsedMilliseconds - _lastPointerMs < 700) {
        // Bedienung läuft: später erneut prüfen (kein Frame-Dauerlauf)
        _retry?.cancel();
        _retry = Timer(const Duration(milliseconds: 300), _schedule);
        return;
      }
      final first = _queue.keys.first;
      final job = _queue.remove(first)!;
      job();
      pending.value = _queue.length;
      _schedule();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Verwirft offene Vorwärm-Aufträge und den Nachprüf-Timer (z. B. beim Schließen des Menüs).
  void cancelPending() {
    _retry?.cancel();
    _retry = null;
    _queue.clear();
    pending.value = 0;
  }

  /// Hält höchstens [megabytes] MB (die zuletzt benutzten); z. B. beim Schließen des Menüs.
  void trim(double megabytes) {
    while (_map.length > 8 && this.megabytes > megabytes) {
      _map.remove(_map.keys.first)?.dispose();
    }
  }

  /// Liefert das gebackene Bild (der Aufrufer muss `clone()` verwenden) oder null.
  ui.Image? get(
    String key,
    Size logical,
    double dpr,
    void Function(Canvas, Size) draw, {
    Offset margin = Offset.zero,
  }) {
    _ensureListening();
    final k = _k(key, logical, dpr, margin);
    _queue.remove(k);
    final hit = _map.remove(k);
    if (hit != null) {
      _map[k] = hit; // als zuletzt benutzt markieren
      return hit;
    }
    try {
      final sw = Stopwatch()..start();
      final w = ((logical.width + 2 * margin.dx) * dpr).ceil();
      final h = ((logical.height + 2 * margin.dy) * dpr).ceil();
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(dpr);
      c.translate(margin.dx, margin.dy);
      draw(c, logical);
      final pic = rec.endRecording();
      final img = pic.toImageSync(w, h);
      pic.dispose();
      bakes++;
      PerfMonitor.instance.cost(
        'bake:${key.split(':').first.split('|').first}',
        sw.elapsedMicroseconds,
      );
      _map[k] = img;
      while (_map.length > maxEntries ||
          (_map.length > 8 && megabytes > maxMegabytes)) {
        final first = _map.keys.first;
        _map
            .remove(first)
            ?.dispose(); // geklonte Handles in Kacheln bleiben gültig
      }
      return img;
    } catch (_) {
      return null;
    }
  }

  void clear() {
    for (final i in _map.values) {
      i.dispose();
    }
    _map.clear();
  }
}

/// Markiert einen unsichtbar gelayouteten Teilbaum, dessen Vorschauen nur vorgewärmt werden.
class PreviewWarmUpScope extends InheritedWidget {
  const PreviewWarmUpScope({super.key, required super.child});
  static bool active(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PreviewWarmUpScope>() != null;
  @override
  bool updateShouldNotify(PreviewWarmUpScope old) => false;
}

/// Zeichnet [paint] einmal gebacken. Gleiche Größe + Schlüssel → derselbe Cache-Eintrag.
class CachedPreview extends StatefulWidget {
  const CachedPreview({
    super.key,
    required this.cacheKey,
    required this.paint,
    this.opacity = 1,
    this.margin = Offset.zero,
    this.alsoBakeDelta,
  });

  /// Eindeutig je Motiv (z. B. `char:dog`); Größe und Pixeldichte kommen automatisch dazu.
  final String cacheKey;
  final void Function(Canvas canvas, Size size) paint;

  /// Abdunkeln gesperrter Einträge ohne Offscreen-Layer.
  final double opacity;

  /// Zweite Größe (aktuelle Größe + Delta), die bei Ruhe vorab gebacken wird – z. B. die Größe der
  /// Kachel im gewählten Zustand, damit das Antippen nichts mehr zeichnen muss.
  final Offset? alsoBakeDelta;

  /// Zusätzlicher Rand um die Größe (z. B. für Schatten) in logischen Pixeln.
  final Offset margin;

  @override
  State<CachedPreview> createState() => _CachedPreviewState();
}

class _CachedPreviewState extends State<CachedPreview> {
  ui.Image? _img;
  String? _forKey;

  void _acquire(Size size, double dpr) {
    final key =
        '${widget.cacheKey}|${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}|${dpr.toStringAsFixed(2)}';
    if (key == _forKey) return;
    _forKey = key;
    _img?.dispose();
    final base = PreviewCache.instance.get(
      widget.cacheKey,
      size,
      dpr,
      widget.paint,
      margin: widget.margin,
    );
    _img = base?.clone();
    final d = widget.alsoBakeDelta;
    if (d != null && base != null) {
      PreviewCache.instance.enqueue(
        widget.cacheKey,
        Size(size.width + d.dx, size.height + d.dy),
        dpr,
        widget.paint,
        margin: widget.margin,
      );
    }
  }

  @override
  void dispose() {
    _img?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
        if (PreviewWarmUpScope.active(context)) {
          PreviewCache.instance.enqueue(
            widget.cacheKey,
            size,
            dpr,
            widget.paint,
            margin: widget.margin,
          );
          return const SizedBox.shrink();
        }
        _acquire(size, dpr);
        final img = _img;
        if (img == null) {
          // Fallback: direkt zeichnen (wie bisher)
          return Opacity(
            opacity: widget.opacity,
            child: CustomPaint(
              size: Size.infinite,
              painter: _DirectPainter(widget.paint),
            ),
          );
        }
        return SizedBox.expand(
          child: OverflowBox(
            minWidth: size.width + 2 * widget.margin.dx,
            maxWidth: size.width + 2 * widget.margin.dx,
            minHeight: size.height + 2 * widget.margin.dy,
            maxHeight: size.height + 2 * widget.margin.dy,
            child: RawImage(
              image: img,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.low,
              opacity: widget.opacity >= 1
                  ? null
                  : AlwaysStoppedAnimation(widget.opacity),
            ),
          ),
        );
      },
    );
  }
}

class _DirectPainter extends CustomPainter {
  _DirectPainter(this.fn);
  final void Function(Canvas, Size) fn;
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(_DirectPainter old) => false;
}
