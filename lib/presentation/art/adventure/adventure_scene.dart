import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/perf_monitor.dart';
import '../../../domain/catalog.dart' show CharacterSpec;
import '../../../domain/timer_engine.dart';
import '../../painters/character_painter.dart' show Mood;
import '../art_kit.dart' show smoothstep;
import '../celebration.dart';
import '../rig.dart' show Emotion;
import '../story/story_quality.dart';
import '../story/story_scene.dart' show StoryController, StoryDirector;
import '../visual/character_visual_painter.dart';
import '../visual/figure_frames.dart';
import '../visual/visual_registry.dart';
import 'adventure_spec.dart';

class _Data {
  double t = 0, u = 0, emotionT = 0;
  Emotion emotion = Emotion.calm;
  bool calm = false, running = false, finished = false;
  StoryTier tier = StoryTier.full;
  double dpr = 1;
  CharacterSpec? spec;
  AdvFrame? frame;
  final Map<int, double> passedAt = {};
  // gebackene statische Ebene
  AdvFrame? bakedFor;
  double bakedDpr = 0;
  ui.Image? baked;
  ui.Picture? picture;
  void disposeBaked() {
    baked?.dispose();
    picture?.dispose();
    baked = null;
    picture = null;
    bakedFor = null;
  }
}

/// Vollbild-Abenteuerszene einer Welt ([AdventureWorldSpec]): gebackene Landschaft (einmal gerendert),
/// bewegte Umgebung (Partikel, Wellen …), Etappen, Ziel und die gewählte Figur auf dem Weg.
///
/// Leistung wie `StoryScene`: kein Neuaufbau pro Bild, drei getrennte RepaintBoundary-Ebenen,
/// Taktung nach Zustand und adaptive Qualitätsstufen ([StoryGovernor]).
class AdventureScene extends StatefulWidget {
  const AdventureScene({
    super.key,
    required this.engine,
    required this.controller,
    required this.fraction,
    required this.calm,
    required this.world,
    this.spec,
    this.breakPhase = false,
    this.powerSave = false,
  });
  final TimerEngine engine;
  final StoryController controller;
  final double Function() fraction;
  final bool calm;
  final AdventureWorldSpec world;
  final CharacterSpec? spec;
  final bool breakPhase;
  final bool powerSave;

  @override
  State<AdventureScene> createState() => _AdventureSceneState();
}

class _AdventureSceneState extends State<AdventureScene>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Timer? _timer;
  final Stopwatch _sw = Stopwatch()..start();
  int _hz = 0;
  final _Data _data = _Data();
  final StoryDirector _dir = StoryDirector();
  final StoryGovernor _gov = StoryGovernor();
  final ValueNotifier<int> _figTick = ValueNotifier(0);
  final ValueNotifier<int> _ambTick = ValueNotifier(0);
  final ValueNotifier<int> _geoTick = ValueNotifier(0);
  double _lastAmbient = -1, _lastProgress = -1;
  late final CustomPainter _back, _ambient, _figure, _celebration;

  @override
  void initState() {
    super.initState();
    PerfMonitor.instance.start();
    widget.controller.stageRect.addListener(_onRect);
    _gov.forceMinimal = widget.powerSave;
    final forced = PerfMonitor.instance.forcedTier;
    if (forced != null) {
      _gov
        ..tier = StoryTier.values.byName(forced)
        ..locked = true;
    }
    _data
      ..calm = widget.calm
      ..spec = widget.spec;
    _back = _BackPainter(_data, widget.world, _geoTick);
    _ambient = _AmbientPainter(
      _data,
      widget.world,
      Listenable.merge([_ambTick, _geoTick]),
    );
    _figure = _FigurePainter(
      _data,
      widget.world,
      Listenable.merge([_figTick, _geoTick]),
    );
    _celebration = _CelebrationPainter(_data, widget.world, _figTick);
    _ticker = createTicker((_) => _onTick(_sw.elapsedMicroseconds / 1e6));
    _onTick(0);
  }

  @override
  void didUpdateWidget(AdventureScene old) {
    super.didUpdateWidget(old);
    _gov.forceMinimal = widget.powerSave;
    if (old.spec?.id != widget.spec?.id) {
      _data.spec = widget.spec;
      _figTick.value++;
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
      ..emotionT = t - _dir.since
      ..calm = widget.calm
      ..running = e.status == TimerStatus.running && !widget.breakPhase
      ..finished = e.status == TimerStatus.finished;
    final st = widget.world.stations;
    for (var i = 1; i < st.length - 1; i++) {
      if (d.u >= st[i] - 0.002) {
        d.passedAt.putIfAbsent(i, () => t);
      } else if (d.u < st[i] - 0.02) {
        d.passedAt.remove(i);
      }
    }
    final c = widget.controller.progress;
    if ((d.u - _lastProgress).abs() >= 0.002 ||
        (d.u == 0 && _lastProgress != 0) ||
        (d.u == 1 && _lastProgress != 1)) {
      _lastProgress = d.u;
      c.value = d.u;
    }
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
    _figTick.value++;
    final ahz = d.calm ? 4 : math.max(StoryGovernor.ambientHz(d.tier), 6);
    if (_lastAmbient < 0 ||
        t - _lastAmbient >= 1 / ahz - 0.002 ||
        tierBefore != d.tier) {
      _lastAmbient = t;
      _ambTick.value++;
    }
  }

  @override
  void dispose() {
    widget.controller.stageRect.removeListener(_onRect);
    _timer?.cancel();
    _ticker.dispose();
    _figTick.dispose();
    _ambTick.dispose();
    _geoTick.dispose();
    _data.disposeBaked();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _data.dpr = MediaQuery.devicePixelRatioOf(context);
    _data.bakedDpr = math.min(_data.dpr, 2.0);
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final rect = widget.controller.stageRect.value;
        // Bis der Bühnenbereich bekannt ist, nur ein neutraler Himmelsgrund (kein Layoutsprung).
        if (rect == null) return const ColoredBox(color: Color(0xFF14204E));
        final bottom = rect.bottom - 62;
        final side = math.max(120.0, math.min(rect.width, bottom - rect.top));
        final box = Rect.fromLTWH(
          rect.center.dx - side / 2,
          bottom - side,
          side,
          side,
        );
        final old = _data.frame;
        if (old == null ||
            old.size != size ||
            old.box != box ||
            _data.bakedFor?.size != size) {
          _data.frame = AdvFrame(size, box, widget.world.control);
          _geoTick.value++;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: CustomPaint(painter: _back)),
            RepaintBoundary(child: CustomPaint(painter: _ambient)),
            RepaintBoundary(child: CustomPaint(painter: _figure)),
            IgnorePointer(
              child: RepaintBoundary(child: CustomPaint(painter: _celebration)),
            ),
          ],
        );
      },
    );
  }
}

class _BackPainter extends CustomPainter {
  _BackPainter(this.d, this.w, Listenable repaint) : super(repaint: repaint);
  final _Data d;
  final AdventureWorldSpec w;

  @override
  void paint(Canvas canvas, Size size) {
    final f = d.frame;
    if (f == null) return;
    if (d.bakedFor != f || d.bakedDpr != _lastDpr) {
      d.disposeBaked();
      _lastDpr = d.bakedDpr;
      final rec = ui.PictureRecorder();
      final rc = Canvas(rec);
      w.paintBack(rc, f);
      w.paintFront?.call(rc, f);
      final pic = rec.endRecording();
      try {
        final k = d.bakedDpr;
        final scaled = ui.PictureRecorder();
        final sc = Canvas(scaled)..scale(k);
        sc.drawPicture(pic);
        final sp = scaled.endRecording();
        d.baked = sp.toImageSync(
          (size.width * k).ceil(),
          (size.height * k).ceil(),
        );
        sp.dispose();
        pic.dispose();
      } catch (_) {
        d.picture = pic;
      }
      d.bakedFor = f;
    }
    final img = d.baked;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else if (d.picture != null) {
      canvas.drawPicture(d.picture!);
    }
  }

  double _lastDpr = 0;
  @override
  bool shouldRepaint(_BackPainter old) => false;
}

class _AmbientPainter extends CustomPainter {
  _AmbientPainter(this.d, this.w, Listenable repaint) : super(repaint: repaint);
  final _Data d;
  final AdventureWorldSpec w;

  @override
  void paint(Canvas canvas, Size size) {
    final f = d.frame;
    if (f == null) return;
    final n = StoryGovernor.particles(d.tier);
    w.paintAmbient(canvas, f, d.t, n, d.calm);
    final st = w.stations;
    for (var i = 1; i < st.length - 1; i++) {
      final at = d.passedAt[i];
      final lit = at == null ? 0.0 : ((d.t - at) / 0.5).clamp(0.0, 1.0);
      final p = f.at(st[i]);
      w.paintStation(canvas, p, f.s * (0.7 + 0.5 * f.depth(p)), lit, d.t);
      if (at != null && !d.calm) {
        final age = d.t - at;
        if (age >= 0 && age < 1.2) {
          final k = age / 1.2;
          canvas.drawCircle(
            p,
            f.s * (0.02 + 0.09 * k),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * (1 - k)
              ..color = Color.fromRGBO(255, 236, 150, 0.9 * (1 - k)),
          );
        }
      }
    }
    final goal = f.p(w.control.last.dx, w.control.last.dy);
    final lit = d.finished ? 1.0 : ((d.u - 0.86) / 0.14).clamp(0.0, 1.0);
    w.paintGoalGlow(canvas, goal, f.s, lit, d.t);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => false;
}

/// Bewegung der Figur auf dem Weg (rein darstellend, nur aus Timer-Zustand abgeleitet):
/// Gehen mit Federn (kurz vor dem Ziel lebhafter), Hüpfer bei erreichter Etappe, Jubeln am Ende,
/// leichtes Winken/Wiegen bei Begrüßung/Start/Ermutigung und seitliches Ausweichen am Ziel,
/// damit die Figur das Zielobjekt nicht verdeckt. Ruhiger Modus: keine Bewegung außer dem Ausweichen.
class FigureMotion {
  const FigureMotion(this.lift, this.rot, this.dx, this.step);
  final double lift, rot, dx, step;

  factory FigureMotion.compute({
    required double u,
    required double t,
    required bool running,
    required bool finished,
    required bool calm,
    required Emotion emotion,
    required double emotionT,
    required Map<int, double> passedAt,
    required double side,
    required bool goalRight,
  }) {
    final dx = smoothstep(0.92, 1.0, u) * side * 0.55 * (goalRight ? -1 : 1);
    if (calm) return FigureMotion(0, 0, dx, 0);
    final near = running && u > 0.9;
    final cadence = near ? 7.4 : 5.6;
    final step = running ? math.sin(t * cadence).abs() : 0.0;
    var lift = -step * side * (near ? 0.10 : 0.07);
    for (final at in passedAt.values) {
      final age = t - at;
      if (age >= 0 && age < 0.9)
        lift -= math.sin(math.pi * age / 0.9) * side * 0.16;
    }
    if (finished && emotionT >= 0 && emotionT < CelebrationPainter.duration) {
      lift -=
          math.sin(emotionT * 5).abs() *
          side *
          0.14 *
          (1 - 0.5 * emotionT / CelebrationPainter.duration);
    }
    var rot = 0.0;
    final gesture =
        emotion == Emotion.greet ||
        emotion == Emotion.encourage ||
        emotion == Emotion.cheer;
    if (gesture && emotionT >= 0 && emotionT < 2.4) {
      rot = math.sin(t * 7) * 0.07 * (1 - emotionT / 2.4);
    }
    return FigureMotion(lift, rot, dx, step);
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.d, this.w, Listenable repaint) : super(repaint: repaint);
  final _Data d;
  final AdventureWorldSpec w;

  @override
  void paint(Canvas canvas, Size size) {
    final f = d.frame;
    final spec = d.spec;
    if (f == null || spec == null) return;
    final pos = f.at(d.u);
    final depth = f.depth(pos);
    var side = f.s * (w.scaleFar + (w.scaleNear - w.scaleFar) * depth) * 1.1;
    if (d.finished) side *= 0.92;
    final t = d.t;
    final goalRight = w.control.last.dx > 0.5;
    final m = FigureMotion.compute(
      u: d.u,
      t: t,
      running: d.running,
      finished: d.finished,
      calm: d.calm,
      emotion: d.emotion,
      emotionT: d.emotionT,
      passedAt: d.passedAt,
      side: side,
      goalRight: goalRight,
    );
    final step = m.step;
    var lift = m.lift;
    if (w.floating)
      lift -= side * 0.10 + (d.calm ? 0 : math.sin(t * 1.6) * side * 0.025);
    final mood = d.finished
        ? Mood.happy
        : d.emotion == Emotion.sleepy
        ? Mood.sleepy
        : d.running
        ? Mood.active
        : Mood.idle;
    final topLeft = Offset(
      pos.dx + m.dx - side / 2,
      pos.dy - side * 0.955 + lift,
    );
    if (w.bubble) {
      final ctr = topLeft + Offset(side / 2, side * 0.52);
      final r = side * 0.62;
      canvas.drawCircle(
        ctr,
        r,
        Paint()
          ..shader = ui.Gradient.radial(
            ctr.translate(-r * 0.3, -r * 0.35),
            r * 1.3,
            const [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
          ),
      );
      canvas.drawCircle(
        ctr,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0x88FFFFFF),
      );
      canvas.drawCircle(
        ctr.translate(-r * 0.45, -r * 0.5),
        r * 0.1,
        Paint()..color = const Color(0xAAFFFFFF),
      );
    }
    if (!w.floating) {
      canvas.drawOval(
        Rect.fromCenter(
          center: pos.translate(m.dx, side * 0.01),
          width: side * (0.5 - step * 0.05 + lift * 0.1 / side),
          height: side * 0.09,
        ),
        Paint()..color = const Color(0x33000000),
      );
    }
    canvas.save();
    if (m.rot != 0) {
      final feet = Offset(pos.dx + m.dx, pos.dy + lift);
      canvas.translate(feet.dx, feet.dy);
      canvas.rotate(m.rot);
      canvas.translate(-feet.dx, -feet.dy);
    }
    final rect = topLeft & Size(side, side);
    // Bild-Figuren (Mira-Mesh) live; Vektor-Figuren als gebackene Frames (siehe FigureFrames)
    if (VisualRegistry.character(spec.id).renderer ==
        FigureRenderer.bitmapMesh) {
      canvas.save();
      canvas.translate(topLeft.dx, topLeft.dy);
      CharacterVisualPainter(
        spec,
        t: t,
        mood: mood,
        calm: d.calm,
        shadow: false,
        emotion: d.emotion,
        emotionT: d.emotionT,
        gearWorld: w.id,
      ).paint(canvas, Size(side, side));
      canvas.restore();
    } else {
      FigureFrames.instance.paint(
        canvas,
        spec,
        rect,
        t: t,
        mood: mood,
        calm: d.calm,
        dpr: d.dpr,
        gearWorld: w.id,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) => false;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.d, this.w, Listenable repaint)
    : super(repaint: repaint);
  final _Data d;
  final AdventureWorldSpec w;

  @override
  void paint(Canvas canvas, Size size) {
    if (!d.finished ||
        d.calm ||
        d.emotionT < 0 ||
        d.emotionT > CelebrationPainter.duration)
      return;
    // Feier am Ziel (nicht in der Bildschirmmitte)
    final f = d.frame;
    final goal = f == null
        ? size.center(Offset.zero)
        : f.p(w.control.last.dx, w.control.last.dy);
    final origin = size.center(Offset(0, -size.height * 0.05));
    canvas.save();
    canvas.translate(
      goal.dx - origin.dx,
      goal.dy - origin.dy - (f?.s ?? 0) * 0.08,
    );
    CelebrationPainter(et: d.emotionT).paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => false;
}
