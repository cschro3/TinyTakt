import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../domain/timer_engine.dart';
import '../../../app/perf_flags.dart';
import '../art_kit.dart';
import '../celebration.dart';
import '../figures/registry.dart';
import '../rig.dart';
import 'art_images.dart';
import 'meadow_path.dart';
import 'meadow_story.dart';
import 'mira_sprite.dart';

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

/// Vollbild-Szene: Blumenwiese (echtes Bild, Mesh-Wind, Licht) + Mira auf dem Weg.
class StoryScene extends StatefulWidget {
  const StoryScene({
    super.key,
    required this.engine,
    required this.controller,
    required this.fraction,
    required this.calm,
    this.breakPhase = false,
  });
  final TimerEngine engine;
  final StoryController controller;
  final double Function() fraction;
  final bool calm;
  final bool breakPhase;

  @override
  State<StoryScene> createState() => _StorySceneState();
}

class _StorySceneState extends State<StoryScene>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);
  final StoryDirector _dir = StoryDirector();
  final Map<int, double> _passedAt = {};
  double _u = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.stageRect.addListener(_onRect);
    _ticker = createTicker((d) {
      final t = d.inMicroseconds / 1e6;
      _tick(t);
      // Ruhiger Modus: nur ca. 4 Bilder/s
      if (widget.calm && (t * 4).floor() == (_t.value * 4).floor()) return;
      _t.value = t;
    })..start();
  }

  void _onRect() => setState(() {});

  void _tick(double t) {
    final e = widget.engine;
    final frac = e.status == TimerStatus.finished ? 0.0 : widget.fraction();
    _dir.update(t, e.status, frac, breakPhase: widget.breakPhase);
    _u = (1 - frac).clamp(0.0, 1.0);
    final su = MeadowPath.instance.stationU;
    for (var i = 1; i < su.length; i++) {
      if (_u >= su[i] - 0.002) {
        _passedAt.putIfAbsent(i, () => t);
      } else if (_u < su[i] - 0.02) {
        _passedAt.remove(i);
      }
    }
    if (widget.controller.progress.value != _u) {
      widget.controller.progress.value = _u;
    }
  }

  @override
  void dispose() {
    widget.controller.stageRect.removeListener(_onRect);
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = ArtImages.instance;
    final meadow = imgs.meadow, mira = imgs.mira;
    if (meadow == null || mira == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final rect = widget.controller.stageRect.value;
        final bottom = rect != null ? rect.bottom - 62 : size.height * 0.5;
        final geo = StoryGeometry(size, pathBottomY: bottom);
        return ValueListenableBuilder<double>(
          valueListenable: _t,
          builder: (context, t, _) {
            final finished = widget.engine.status == TimerStatus.finished;
            final et = t - _dir.since;
            final celebrate =
                finished &&
                !widget.calm &&
                et >= 0 &&
                et <= CelebrationPainter.duration;
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: MeadowBackdropPainter(
                    image: meadow,
                    geo: geo,
                    t: widget.calm ? 0 : t,
                    calm: widget.calm,
                  ),
                ),
                CustomPaint(
                  painter: _MiraLayerPainter(
                    mira: mira,
                    geo: geo,
                    t: t,
                    calm: widget.calm,
                    u: _u,
                    running:
                        widget.engine.status == TimerStatus.running &&
                        !widget.breakPhase,
                    finished: finished,
                    emotion: _dir.emotion,
                    emotionT: et,
                    passedAt: Map.of(_passedAt),
                  ),
                ),
                if (celebrate)
                  IgnorePointer(
                    child: CustomPaint(painter: CelebrationPainter(et: et)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MiraLayerPainter extends CustomPainter {
  _MiraLayerPainter({
    required this.mira,
    required this.geo,
    required this.t,
    required this.calm,
    required this.u,
    required this.running,
    required this.finished,
    required this.emotion,
    required this.emotionT,
    required this.passedAt,
  });
  final ui.Image mira;
  final StoryGeometry geo;
  final double t, u, emotionT;
  final bool calm, running, finished;
  final Emotion emotion;
  final Map<int, double> passedAt;

  @override
  void paint(Canvas canvas, Size size) {
    if (perfOff('mira')) return;
    final path = MeadowPath.instance;
    final s = geo.s;
    // Etappen: erreichte Sternsteine leuchten, der nächste pulsiert, frisch erreichte „platzen“ auf
    var next = -1;
    for (var i = 0; i < MeadowPath.stones.length; i++) {
      final sp = geo.toScreen(MeadowPath.stones[i]);
      final lit = i == 0 || passedAt.containsKey(i);
      final r = 46 * s * geo.depthScale(MeadowPath.stones[i].dy) / 0.325 * 0.85;
      if (lit) {
        canvas.drawCircle(
          sp,
          r,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.radial(sp, r, [
              const Color(0x66FFE27A),
              const Color(0x00FFE27A),
            ]),
        );
      } else if (next < 0) {
        next = i;
        final pulse = calm ? 0.6 : 0.5 + 0.5 * math.sin(t * 3);
        canvas.drawCircle(
          sp,
          r * 0.9,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = ui.Gradient.radial(sp, r * 0.9, [
              Color.fromRGBO(255, 244, 190, 0.22 + 0.25 * pulse),
              const Color(0x00FFF4BE),
            ]),
        );
      }
    }
    // Mira
    final img = path.at(u);
    final feet = geo.toScreen(img).translate(0, 2);
    final h = 370 * s * geo.depthScale(img.dy);
    final pose = computePose(
      premiumFigures['nova_mira']!.personality,
      emotion,
      t,
      emotionT,
      calm: calm,
    );
    if (running && !calm) {
      final step = math.sin(t * 5.6).abs();
      pose.bodyDy -= step * 0.10;
      pose.squash += step < 0.18 ? 0.45 : -0.08;
      pose.lean += math.sin(t * 5.6) * 0.03;
    }
    MiraMesh.shadow(canvas, feet, h * 0.9, (-pose.bodyDy).clamp(0.0, 0.4) * 2);
    MiraMesh.paint(canvas, mira, feet, h, pose, t, calm: calm);
    if (!calm) {
      MiraMesh.sparkles(
        canvas,
        feet.translate(0, -h * 0.55),
        h * 0.55,
        pose.sparkle,
        t,
      );
    }
    // Aufplatzen frisch erreichter Steine
    for (final e in passedAt.entries) {
      final age = t - e.value;
      if (age < 0 || age > 1.2 || calm) continue;
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
    // Ziel: Haustür leuchtet, wenn Mira angekommen ist
    if (finished) {
      final door = geo.toScreen(const Offset(1030, 385));
      final r = 80 * s;
      canvas.drawCircle(
        door,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = ui.Gradient.radial(door, r, [
            Color.fromRGBO(
              255,
              214,
              120,
              0.55 + (calm ? 0 : 0.2 * math.sin(t * 3)),
            ),
            const Color(0x00FFD678),
          ]),
      );
    }
  }

  @override
  bool shouldRepaint(_MiraLayerPainter o) => true;
}

/// Bühnen-Slot im Layout: meldet seinen Bereich, zeigt Fortschritt und Countdown
/// als echte Flutter-Komponenten.
class StoryStage extends StatefulWidget {
  const StoryStage({
    super.key,
    required this.controller,
    this.countdown,
    this.semanticsLabel = 'Fortschritt',
  });
  final StoryController controller;
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
  });
  final ValueListenable<double> progress;
  final String label;

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
                final su = MeadowPath.instance.stationU;
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B3FE0), Color(0xFFB97BFF)],
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
