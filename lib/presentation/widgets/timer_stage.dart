import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/catalog.dart';
import '../../domain/timer_engine.dart';
import '../art/celebration.dart';
import '../art/rig.dart';
import '../painters/character_painter.dart';
import '../painters/picture_painters.dart';
import '../painters/timer_painters.dart';

/// Motiv in der Bühne: Figur oder eigenes Foto (Pro).
class Motif {
  const Motif.character(this.spec) : photo = null;
  const Motif.photo(this.photo) : spec = null;
  final CharacterSpec? spec;
  final File? photo;
}

/// Die zentrale visuelle Zeitdarstellung. Kennt nur [engine] (Lesezugriff) –
/// keine Zeitlogik, keine Seiteneffekte. Animation läuft über einen Ticker.
class TimerStage extends StatefulWidget {
  const TimerStage({
    super.key,
    required this.engine,
    required this.style,
    required this.motif,
    required this.calm,
    this.countdown,
    this.fraction,
    this.breakPhase = false,
    this.scenery = Scenery.meadow,
  });
  final TimerEngine engine;
  final TimerStyle style;
  final Motif motif;
  final bool calm;
  final int? countdown;

  /// Anteil der aktuellen Phase (1 → 0); ohne Angabe der Restanteil der Engine.
  final double Function()? fraction;

  /// Pausenphase im Lern-/Spielplan: ruhige Figur, blauer Ring.
  final bool breakPhase;

  /// Gewählte Welt (färbt das Abenteuer-Diorama passend).
  final Scenery scenery;

  @override
  State<TimerStage> createState() => _TimerStageState();
}

class _TimerStageState extends State<TimerStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);

  // Regie der Figur: reagiert auf Timer-Ereignisse (Begrüßung, Start, Ermutigung, Abschluss)
  Emotion _emo = Emotion.calm;
  double _emoAt = 0;
  double _now = 0;
  TimerStatus? _lastStatus;
  double _lastFrac = 1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      // Ruhiger Modus: nur ca. 4 Bilder/s für den Ring, spart Akku.
      final t = d.inMicroseconds / 1e6;
      _now = t;
      _direct(t);
      if (widget.calm && (t * 4).floor() == (_t.value * 4).floor()) return;
      _t.value = t;
    })..start();
  }

  void _setEmotion(Emotion e, double t, {double delay = 0}) {
    _emo = e;
    _emoAt = t + delay;
  }

  /// Leitet aus Timer-Zustand und Fortschritt die Gefühlslage der Figur ab.
  void _direct(double t) {
    final e = widget.engine;
    final st = e.status;
    final frac = widget.fraction?.call() ?? e.fractionRemaining;
    if (_lastStatus == null) {
      _setEmotion(
        Emotion.greet,
        t,
        delay: 0.5,
      ); // freundliche Begrüßung beim Erscheinen
    } else if (st != _lastStatus) {
      switch (st) {
        case TimerStatus.running:
          _setEmotion(Emotion.cheer, t);
        case TimerStatus.finished:
          _setEmotion(Emotion.celebrate, t);
        case TimerStatus.paused:
          _setEmotion(Emotion.sleepy, t);
        case TimerStatus.idle:
          _setEmotion(Emotion.calm, t);
      }
    } else if (st == TimerStatus.running && !widget.breakPhase) {
      for (final th in const [0.75, 0.5, 0.25]) {
        if (_lastFrac > th && frac <= th && t - _emoAt > 2.2)
          _setEmotion(Emotion.encourage, t);
      }
    }
    final age = t - _emoAt;
    if ((_emo == Emotion.cheer && age > 1.8) ||
        (_emo == Emotion.greet && age > 2.4) ||
        (_emo == Emotion.encourage && age > 2.2)) {
      _emo = Emotion.calm;
    }
    _lastStatus = st;
    _lastFrac = frac;
  }

  @override
  void didUpdateWidget(TimerStage old) {
    super.didUpdateWidget(old);
    if (old.motif.spec?.id != widget.motif.spec?.id &&
        widget.motif.spec != null) {
      _setEmotion(Emotion.greet, _now); // neue Figur begrüßt kurz
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  Mood get _mood {
    if (widget.countdown != null) return Mood.happy;
    switch (widget.engine.status) {
      case TimerStatus.running:
        return widget.breakPhase ? Mood.idle : Mood.active;
      case TimerStatus.paused:
        return Mood.sleepy;
      case TimerStatus.finished:
        return Mood.happy;
      case TimerStatus.idle:
        return Mood.idle;
    }
  }

  Widget _figure(double size, double t, {double rotate = 0}) {
    final m = widget.motif;
    final child = m.spec != null
        ? SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: CharacterPainter(
                m.spec!,
                t: t,
                mood: _mood,
                calm: widget.calm,
                shadow: false,
                emotion: _emo,
                emotionT: t - _emoAt,
              ),
            ),
          )
        : SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: size * 0.04),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 12),
                ],
              ),
              child: ClipOval(
                child: Image.file(
                  m.photo!,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: Colors.white),
                ),
              ),
            ),
          );
    return rotate == 0 ? child : Transform.rotate(angle: rotate, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ValueListenableBuilder<double>(
              valueListenable: _t,
              builder: (context, t, _) {
                final et = t - _emoAt;
                final celebrate =
                    widget.engine.status == TimerStatus.finished &&
                    !widget.calm &&
                    et >= 0 &&
                    et <= CelebrationPainter.duration;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildStage(context, t, side),
                    if (celebrate)
                      IgnorePointer(
                        child: CustomPaint(painter: CelebrationPainter(et: et)),
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

  Widget _buildStage(BuildContext context, double t, double side) {
    final e = widget.engine;
    final frac = e.status == TimerStatus.finished
        ? 0.0
        : (widget.fraction?.call() ?? e.fractionRemaining);
    final calm = widget.calm;
    final size = Size(side, side);
    final ring = _ringColor(frac);
    switch (widget.style) {
      case TimerStyle.circle:
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: size,
              painter: RingPainter(fraction: frac, color: ring),
            ),
            _figure(side * 0.6, t),
            if (widget.countdown != null) _countdown(side),
          ],
        );
      case TimerStyle.adventure:
        final track = AdventureTrack(size);
        final pos = track.at(1 - frac);
        final fs =
            side *
            0.34 *
            (e.status == TimerStatus.finished ? 0.9 : track.scaleAt(1 - frac));
        final hop = calm || e.status != TimerStatus.running
            ? 0.0
            : -math.sin(t * 6).abs() * side * 0.025;
        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: AdventurePainter(fraction: frac, t: t, calm: calm),
            ),
            Positioned(
              left: pos.dx - fs / 2,
              top: pos.dy - fs * 0.85 + hop,
              child: _figure(fs, t),
            ),
            if (widget.countdown != null) _countdown(side),
          ],
        );
      case TimerStyle.fill:
        final g = FillGeometry(size);
        final fs = side * 0.4;
        final y = g.surfaceY(frac);
        final bob = calm ? 0.0 : math.sin(t * 2) * 4;
        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: FillPainter(
                fraction: frac,
                t: t,
                color: ring,
                calm: calm,
              ),
            ),
            Positioned(
              left: side / 2 - fs / 2,
              top: (y - fs * 0.75 + bob).clamp(
                g.glass.top - fs * 0.3,
                g.glass.bottom - fs,
              ),
              child: _figure(fs, t),
            ),
            if (widget.countdown != null) _countdown(side),
          ],
        );
      case TimerStyle.rainbow:
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: size,
              painter: RainbowPainter(fraction: frac),
            ),
            Positioned(bottom: side * 0.04, child: _figure(side * 0.42, t)),
            if (widget.countdown != null) _countdown(side),
          ],
        );
      case TimerStyle.hourglass:
        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: HourglassPainter(fraction: frac, t: t, calm: calm),
            ),
            Positioned(
              right: 0,
              bottom: side * 0.02,
              child: _figure(side * 0.3, t),
            ),
            if (widget.countdown != null) _countdown(side),
          ],
        );
      case TimerStyle.iceCream:
      case TimerStyle.candle:
      case TimerStyle.plant:
      case TimerStyle.pizza:
      case TimerStyle.puzzle:
        // Das Bild ist die Zeit; die Figur schaut klein von unten rechts zu.
        return Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(side * 0.04),
                child: CustomPaint(
                  painter: PicturePainter(
                    style: widget.style,
                    fraction: frac,
                    t: t,
                    calm: calm,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: side * 0.02,
              child: _figure(side * 0.26, t),
            ),
            if (widget.countdown != null) _countdown(side),
          ],
        );
    }
  }

  /// Farbe des Fortschritts (nur unterstützend; Zeit steht zusätzlich als Zahl und Form da).
  Color _ringColor(double frac) {
    if (widget.breakPhase)
      return const Color(0xFF5BA8F0); // Pause: ruhiges Blau
    if (frac > 0.5) return const Color(0xFF2FC4A8);
    if (frac > 0.2) return const Color(0xFFFFB02E);
    return const Color(0xFFFF7A59);
  }

  Widget _countdown(double side) => Center(
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
  );
}
