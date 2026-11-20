import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/timer_engine.dart';
import '../../../app/perf_flags.dart';
import '../../../app/perf_monitor.dart';
import '../../../domain/catalog.dart' show CharacterSpec;
import '../../painters/character_painter.dart' show Mood;
import '../art_kit.dart';
import '../visual/figure_frames.dart';
import '../visual/visual_registry.dart';
import '../celebration.dart';
import '../figures/registry.dart';
import '../rig.dart';
import 'art_images.dart';
import 'meadow_path.dart';
import 'meadow_story.dart';
import 'mira_sprite.dart';
import 'story_quality.dart';

/// Gemeinsamer Zustand von Hintergrund-Szene, Bühne und Fortschrittsleiste.
class StoryController {
  /// Bereich der Bühne im Bildschirm (von [StoryStage] gemeldet).
  final ValueNotifier<Rect?> stageRect = ValueNotifier(null);

  /// Fortschritt 0 (Start) … 1 (Ziel); wird von [StoryScene] je Bild aktualisiert.
  final ValueNotifier<double> progress = ValueNotifier(0);

  void dispose() {
    stageRect.dispose();
    progress.dispose();
  }
}

/// Leitet aus Timer-Zustand und Fortschritt die Gefühlslage ab (Begrüßung, Start,
/// Ermutigung bei 75/50/25 %, Jubel am Ende, müde in der Pause).
class StoryDirector {
  Emotion emotion = Emotion.calm;
  double since = 0;
  TimerStatus? _lastStatus;
  double _lastFrac = 1;

  void set(Emotion e, double t, {double delay = 0}) {
    emotion = e;
    since = t + delay;
  }

  void update(
    double t,
    TimerStatus st,
    double frac, {
    bool breakPhase = false,
  }) {
    if (_lastStatus == null) {
      set(Emotion.greet, t, delay: 0.5);
    } else if (st != _lastStatus) {
      switch (st) {
        case TimerStatus.running:
          set(Emotion.cheer, t);
        case TimerStatus.finished:
          set(Emotion.celebrate, t);
        case TimerStatus.paused:
          set(Emotion.sleepy, t);
        case TimerStatus.idle:
          set(Emotion.calm, t);
      }
    } else if (st == TimerStatus.running && !breakPhase) {
      for (final th in const [0.75, 0.5, 0.25]) {
        if (_lastFrac > th && frac <= th && t - since > 2.2) {
          set(Emotion.encourage, t);
        }
      }
    }
    final age = t - since;
    if ((emotion == Emotion.cheer && age > 1.8) ||
        (emotion == Emotion.greet && age > 2.4) ||
        (emotion == Emotion.encourage && age > 2.2)) {
      emotion = Emotion.calm;
    }
    _lastStatus = st;
    _lastFrac = frac;
  }
}

/// Von den Zeichenebenen gemeinsam gelesene Szenendaten (werden je Takt aktualisiert,
/// ohne dass Widgets neu aufgebaut werden).
class _SceneData {
  double t = 0, u = 0, emotionT = 0, emotionSince = 0, dpr = 1;
  Emotion emotion = Emotion.calm;
  bool calm = false, running = false, finished = false;
  StoryTier tier = StoryTier.full;
  CharacterSpec? spec;
  final Map<int, double> passedAt = {};
  StoryGeometry? geo;
  MeadowAmbient? ambient;
  ui.Image? _ambientSrc;
}

/// Vollbild-Szene: Blumenwiese (echtes Bild, gebackene statische Ebene, Wind, Licht) + Mira.
///
/// Leistung (siehe `docs/PERFORMANCE.md`): kein Neuaufbau pro Bild, vier getrennte
/// `RepaintBoundary`-Ebenen (statisch · Hintergrundleben · Mira · Feier), Taktung nach Stufe und
/// Zustand (Ticker nur bei 60 Hz, sonst Timer), adaptive Qualität über [StoryGovernor].
class StoryScene extends StatefulWidget {
  const StoryScene({
    super.key,
    required this.engine,
    required this.controller,
    required this.fraction,
    required this.calm,
    this.breakPhase = false,
    this.powerSave = false,
    this.spec,
  });

  /// Figur auf dem Weg; ohne Angabe Mira. Bild-Figuren nutzen das Mesh, alle anderen den
  /// gemeinsamen Figuren-Renderer (Vektor-Fallback, gleiche Bahn und Etappen).
  final CharacterSpec? spec;
  final TimerEngine engine;
  final StoryController controller;
  final double Function() fraction;
  final bool calm;
  final bool breakPhase;
  final bool powerSave;

  @override
  State<StoryScene> createState() => _StorySceneState();
}

class _StorySceneState extends State<StoryScene>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Timer? _timer;
  final Stopwatch _sw = Stopwatch()..start();
  int _hz = 0;
  final _SceneData _data = _SceneData();
  final StoryDirector _dir = StoryDirector();
  final StoryGovernor _gov = StoryGovernor();
  final ValueNotifier<int> _miraTick = ValueNotifier(0);
  final ValueNotifier<int> _ambientTick = ValueNotifier(0);
  final ValueNotifier<int> _geoTick = ValueNotifier(0);
  double _lastAmbient = -1, _lastProgress = -1;
  late final CustomPainter _staticPainter,
      _ambientPainter,
      _miraPainter,
      _celebrationPainter;

  @override
  void initState() {
    super.initState();
    final pm = PerfMonitor.instance..start();
    pm.mark('sceneInit');
    widget.controller.stageRect.addListener(_onRect);
    _gov.forceMinimal = widget.powerSave;
    final forced = pm.forcedTier;
    if (forced != null) {
      _gov
        ..tier = StoryTier.values.byName(forced)
        ..locked = true;
    }
    _data.calm = widget.calm;
    _data.spec = widget.spec;
    _staticPainter = _StaticPainter(_data, _geoTick);
    _ambientPainter = _AmbientPainter(
      _data,
      Listenable.merge([_ambientTick, _geoTick]),
    );
    _miraPainter = _MiraPainter(_data, Listenable.merge([_miraTick, _geoTick]));
    _celebrationPainter = _CelebrationPainter(_data, _miraTick);
    _ticker = createTicker((_) => _onTick(_sw.elapsedMicroseconds / 1e6));
    _onTick(0);
  }

  @override
  void didUpdateWidget(StoryScene old) {
    super.didUpdateWidget(old);
    _gov.forceMinimal = widget.powerSave;
    if (old.spec?.id != widget.spec?.id) {
      _data.spec = widget.spec;
      _miraTick.value++;
    }
    if (old.calm != widget.calm || old.powerSave != widget.powerSave) {
      _data.calm = widget.calm;
      _onTick(_sw.elapsedMicroseconds / 1e6);
      _geoTick.value++;
    }
  }

  void _onRect() {
    if (mounted) setState(() {});
  }

  bool get _visible {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  void _setHz(int hz) {
    if (hz == _hz) return;
    _hz = hz;
    _timer?.cancel();
    _timer = null;
    if (hz >= 50) {
      if (!_ticker.isActive) _ticker.start();
      _ticker.muted = false;
    } else {
      if (_ticker.isActive) _ticker.muted = true;
      _timer = Timer.periodic(
        Duration(microseconds: (1e6 / hz).round()),
        (_) => _onTick(_sw.elapsedMicroseconds / 1e6),
      );
    }
  }

  void _onTick(double t) {
    if (!mounted) return;
    final e = widget.engine;
    final d = _data;
    final frac = e.status == TimerStatus.finished ? 0.0 : widget.fraction();
    _dir.update(t, e.status, frac, breakPhase: widget.breakPhase);
    d
      ..t = t
      ..u = (1 - frac).clamp(0.0, 1.0)
      ..emotion = _dir.emotion
      ..emotionSince = _dir.since
      ..emotionT = t - _dir.since
      ..calm = widget.calm
      ..running = e.status == TimerStatus.running && !widget.breakPhase
      ..finished = e.status == TimerStatus.finished;
    final su = MeadowPath.instance.stationU;
    for (var i = 1; i < su.length; i++) {
      if (d.u >= su[i] - 0.002) {
        d.passedAt.putIfAbsent(i, () => t);
      } else if (d.u < su[i] - 0.02) {
        d.passedAt.remove(i);
      }
    }
    // Fortschrittsleiste nur bei sichtbarer Änderung (< 1 px) aktualisieren
    final c = widget.controller.progress;
    if ((d.u - _lastProgress).abs() >= 0.002 ||
        (d.u == 0 && _lastProgress != 0) ||
        (d.u == 1 && _lastProgress != 1)) {
      _lastProgress = d.u;
      c.value = d.u;
    }
    // Takt und Qualitätsstufe
    final celebrating =
        d.finished &&
        d.emotionT >= 0 &&
        d.emotionT <= CelebrationPainter.duration;
    final active = d.running || celebrating || _dir.emotion != Emotion.calm;
    final tierBefore = _gov.effective;
    final hz = d.calm
        ? 4
        : StoryGovernor.sceneHz(_gov.effective, active: active);
    _gov.evaluate(t, hz, visible: _visible);
    d.tier = _gov.effective;
    final pm = PerfMonitor.instance;
    pm.tier = d.calm ? 'ruhig' : d.tier.name;
    pm.rateHz = hz;
    _setHz(d.calm ? 4 : StoryGovernor.sceneHz(d.tier, active: active));
    _miraTick.value++;
    final ahz = d.calm ? 0 : StoryGovernor.ambientHz(d.tier);
    final tierChanged = tierBefore != d.tier;
    if (ahz > 0 && (_lastAmbient < 0 || t - _lastAmbient >= 1 / ahz - 0.002)) {
      _lastAmbient = t;
      _ambientTick.value++;
    } else if (tierChanged) {
      _ambientTick.value++;
    }
  }

  @override
  void dispose() {
    widget.controller.stageRect.removeListener(_onRect);
    _timer?.cancel();
    _ticker.dispose();
    _miraTick.dispose();
    _ambientTick.dispose();
    _geoTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = ArtImages.instance;
    if (imgs.meadow == null || imgs.mira == null)
      return const SizedBox.shrink();
    _data.dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final rect = widget.controller.stageRect.value;
        // Bis der Bühnenbereich gemeldet ist (erstes Bild), nur der Himmelsgrund – so wird die
        // Wiese nicht erst an falscher Stelle gebacken.
        if (rect == null) return const ColoredBox(color: Color(0xFF9BD2F5));
        final bottom = rect.bottom - 62;
        final old = _data.geo;
        if (old == null ||
            old.size != size ||
            (old.pathBottomY - bottom).abs() > 0.5) {
          _data.geo = StoryGeometry(size, pathBottomY: bottom);
          _data.ambient = null;
          _geoTick.value++;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: CustomPaint(painter: _staticPainter)),
            RepaintBoundary(child: CustomPaint(painter: _ambientPainter)),
            RepaintBoundary(child: CustomPaint(painter: _miraPainter)),
            IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _celebrationPainter),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Ebene 1: die gebackene statische Wiese (einmal gerendert, danach nur ein Bild-Quad).
class _StaticPainter extends CustomPainter {
  _StaticPainter(this.d, Listenable repaint) : super(repaint: repaint);
  final _SceneData d;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = d.geo;
    final imgs = ArtImages.instance;
    final meadow = imgs.meadow;
    if (geo == null || meadow == null) return;
    final sw = Stopwatch()..start();
    final scale = math.min(d.dpr, 1500 / size.width).clamp(1.0, 3.0);
    final baked = BackdropCache.staticImage(
      meadow,
      imgs.meadowScale,
      geo,
      size,
      scale,
    );
    if (baked != null) {
      canvas.drawImageRect(
        baked,
        Rect.fromLTWH(0, 0, baked.width.toDouble(), baked.height.toDouble()),
        Offset.zero & size,
        // opak und unterste Ebene: ohne Blending (kein Lesen des Hintergrunds)
        Paint()
          ..filterQuality = FilterQuality.low
          ..blendMode = BlendMode.src,
      );
    } else {
      canvas.drawPicture(
        BackdropCache.staticPicture(meadow, imgs.meadowScale, geo, size),
      );
    }
    final pm = PerfMonitor.instance;
    pm.textureMB = imgs.textureMB + BackdropCache.bakedMB;
    pm.mark('staticReady');
    pm.cost('static', sw.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(_StaticPainter old) => false;
}

/// Ebene 2: Hintergrundleben (Wind, Strahlen, Glühen, Funkeln, Pollen), mit gedrosselter Rate.
class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.d, Listenable repaint) : super(repaint: repaint);
  final _SceneData d;

  @override
  void paint(Canvas canvas, Size size) {
    final geo = d.geo;
    final imgs = ArtImages.instance;
    final meadow = imgs.meadow;
    if (geo == null || meadow == null || d.calm) return;
    final sw = Stopwatch()..start();
    if (d.ambient == null || d._ambientSrc != meadow) {
      d.ambient = MeadowAmbient(
        geo: geo,
        size: size,
        src: meadow,
        texScale: imgs.meadowScale,
      );
      d._ambientSrc = meadow;
    }
    d.ambient!.paint(canvas, d.t, tier: d.tier, calm: d.calm);
    PerfMonitor.instance.cost('ambient', sw.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => false;
}

/// Ebene 3: Etappen-Glühen, Mira, Funken, Haustür.
class _MiraPainter extends CustomPainter {
  _MiraPainter(this.d, Listenable repaint) : super(repaint: repaint);
  final _SceneData d;

  /// Figuren ohne Bild-Asset: gemeinsamer Figuren-Renderer auf derselben Bahn.
  void _paintVectorFigure(
    Canvas canvas,
    CharacterSpec spec,
    Offset feet,
    double h,
  ) {
    final side = h * 1.1;
    final step = d.running && !d.calm ? math.sin(d.t * 5.6).abs() : 0.0;
    final mood = d.finished
        ? Mood.happy
        : d.emotion == Emotion.sleepy
        ? Mood.sleepy
        : d.running
        ? Mood.active
        : Mood.idle;
    final top = Offset(
      feet.dx - side / 2,
      feet.dy - side * 0.965 - step * h * 0.08,
    );
    FigureFrames.instance.paint(
      canvas,
      spec,
      top & Size(side, side),
      t: d.t,
      mood: mood,
      calm: d.calm,
      dpr: d.dpr,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final geo = d.geo;
    final mesh = ArtImages.instance.miraMesh;
    final spec = d.spec;
    final vector =
        spec != null &&
        VisualRegistry.character(spec.id).renderer != FigureRenderer.bitmapMesh;
    if (geo == null || (mesh == null && !vector) || perfOff('mira')) return;
    final sw = Stopwatch()..start();
    final path = MeadowPath.instance;
    final s = geo.s;
    final t = d.t, calm = d.calm;
    // Etappen: erreichte Sternsteine leuchten, der nächste pulsiert, frisch erreichte „platzen“ auf
    var next = -1;
    for (var i = 0; i < MeadowPath.stones.length; i++) {
      final sp = geo.toScreen(MeadowPath.stones[i]);
      final lit = i == 0 || d.passedAt.containsKey(i);
      final r = 46 * s * geo.depthScale(MeadowPath.stones[i].dy) / 0.325 * 0.85;
      if (lit) {
        MeadowAmbient.paintGlow(canvas, sp, r, const Color(0xFFFFE27A), 0.4);
      } else if (next < 0) {
        next = i;
        final pulse = calm ? 0.6 : 0.5 + 0.5 * math.sin(t * 3);
        MeadowAmbient.paintGlow(
          canvas,
          sp,
          r * 0.9,
          const Color(0xFFFFF4BE),
          0.22 + 0.25 * pulse,
        );
      }
    }
    // Mira
    final img = path.at(d.u);
    final feet = geo.toScreen(img).translate(0, 2);
    final h = 370 * s * geo.depthScale(img.dy);
    if (vector) {
      _paintVectorFigure(canvas, spec, feet, h);
    } else {
      final pose = computePose(
        premiumFigures['nova_mira']!.personality,
        d.emotion,
        t,
        d.emotionT,
        calm: calm,
      );
      if (d.running && !calm) {
        final step = math.sin(t * 5.6).abs();
        pose.bodyDy -= step * 0.10;
        pose.squash += step < 0.18 ? 0.45 : -0.08;
        pose.lean += math.sin(t * 5.6) * 0.03;
      }
      MiraMesh.shadow(
        canvas,
        feet,
        h * 0.9,
        (-pose.bodyDy).clamp(0.0, 0.4) * 2,
      );
      MiraMesh.paint(canvas, mesh!, feet, h, pose, t, calm: calm);
      if (!calm) {
        MiraMesh.sparkles(
          canvas,
          feet.translate(0, -h * 0.55),
          h * 0.55,
          pose.sparkle,
          t,
        );
      }
    }
    // Aufplatzen frisch erreichter Steine
    if (!calm) {
      for (final e in d.passedAt.entries) {
        final age = t - e.value;
        if (age < 0 || age > 1.2) continue;
        final sp = geo.toScreen(MeadowPath.stones[e.key]);
        final k = age / 1.2;
        canvas.drawCircle(
          sp,
          (16 + 60 * k) * s / 0.325,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3 * (1 - k)
            ..color = Color.fromRGBO(255, 236, 150, 0.9 * (1 - k)),
        );
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + 0.4;
          sparkleStar(
            canvas,
            sp + Offset(math.cos(a), math.sin(a)) * (10 + 50 * k) * s / 0.325,
            (7 * (1 - k)) * s / 0.325 + 1,
            Colors.white,
          );
        }
      }
    }
    // Ziel: Haustür leuchtet, wenn Mira angekommen ist
    if (d.finished) {
      final door = geo.toScreen(const Offset(1030, 385));
      MeadowAmbient.paintGlow(
        canvas,
        door,
        80 * s,
        const Color(0xFFFFD678),
        0.55 + (calm ? 0 : 0.2 * math.sin(t * 3)),
      );
    }
    PerfMonitor.instance.cost('mira', sw.elapsedMicroseconds);
  }

  @override
  bool shouldRepaint(_MiraPainter old) => false;
}

/// Ebene 4: Konfetti am Ende (nur in den ersten Sekunden sichtbar).
class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.d, Listenable repaint) : super(repaint: repaint);
  final _SceneData d;

  @override
  void paint(Canvas canvas, Size size) {
    if (!d.finished || d.calm) return;
    final et = d.emotionT;
    if (et < 0 || et > CelebrationPainter.duration) return;
    CelebrationPainter(et: et).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => false;
}

/// Bühnen-Slot im Layout: meldet seinen Bereich, zeigt Fortschritt und Countdown
/// als echte Flutter-Komponenten.
class StoryStage extends StatefulWidget {
  const StoryStage({
    super.key,
    required this.controller,
    this.countdown,
    this.semanticsLabel = 'Fortschritt',
    this.stations,
    this.barColors,
  });
  final StoryController controller;
  final List<double>? stations;
  final List<Color>? barColors;
  final int? countdown;
  final String semanticsLabel;

  @override
  State<StoryStage> createState() => _StoryStageState();
}

class _StoryStageState extends State<StoryStage> {
  void _report() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final r = box.localToGlobal(Offset.zero) & box.size;
    if (widget.controller.stageRect.value != r)
      widget.controller.stageRect.value = r;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        return Stack(
          children: [
            if (widget.countdown != null)
              Center(
                child: Container(
                  width: side * 0.4,
                  height: side * 0.4,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xE63B2F7F),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${widget.countdown}',
                    style: TextStyle(
                      fontSize: side * 0.26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 8,
              child: StoryProgressBar(
                progress: widget.controller.progress,
                label: widget.semanticsLabel,
                stations: widget.stations,
                colors: widget.barColors,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Fortschrittsleiste als Flutter-Widget (kein Bild): violetter Balken mit leuchtendem
/// Stern und einem Punkt je Etappe.
class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.progress,
    required this.label,
    this.stations,
    this.colors,
  });
  final ValueListenable<double> progress;
  final String label;

  /// Etappen (Anteil 0…1, erster und letzter Wert = Start/Ziel); ohne Angabe die der Wiese.
  final List<double>? stations;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, p, _) {
        return Semantics(
          label: label,
          value: '${(p * 100).round()} %',
          child: SizedBox(
            height: 34,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final x = (w * p).clamp(0.0, w);
                final su = stations ?? MeadowPath.instance.stationU;
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: const Color(0x66FFFFFF),
                        border: Border.all(
                          color: const Color(0xCCFFFFFF),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33201060),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: x,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        gradient: LinearGradient(
                          colors:
                              colors ??
                              const [Color(0xFF7B3FE0), Color(0xFFB97BFF)],
                        ),
                      ),
                    ),
                    for (var i = 1; i < su.length - 1; i++)
                      Positioned(
                        left: w * su[i] - 3,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p >= su[i]
                                ? Colors.white
                                : const Color(0x99FFFFFF),
                          ),
                        ),
                      ),
                    Positioned(
                      left: x - 15,
                      child: const Icon(
                        Icons.star_rounded,
                        size: 30,
                        color: Color(0xFFFFD23F),
                        shadows: [
                          Shadow(color: Color(0xFFFFB300), blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
