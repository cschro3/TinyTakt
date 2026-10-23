import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/catalog.dart';
import '../../domain/timer_engine.dart';
import '../painters/character_painter.dart';
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
  });
  final TimerEngine engine;
  final TimerStyle style;
  final Motif motif;
  final bool calm;
  final int? countdown;

  @override
  State<TimerStage> createState() => _TimerStageState();
}

class _TimerStageState extends State<TimerStage>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      // Ruhiger Modus: nur ca. 4 Bilder/s für den Ring, spart Akku.
      final t = d.inMicroseconds / 1e6;
      if (widget.calm && (t * 4).floor() == (_t.value * 4).floor()) return;
      _t.value = t;
    })..start();
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
        return Mood.active;
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
                final e = widget.engine;
                final frac = e.status == TimerStatus.finished
                    ? 0.0
                    : e.fractionRemaining;
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
                    final fs = side * 0.34;
                    final hop = calm || e.status != TimerStatus.running
                        ? 0.0
                        : -math.sin(t * 6).abs() * side * 0.025;
                    return Stack(
                      children: [
                        CustomPaint(
                          size: size,
                          painter: AdventurePainter(
                            fraction: frac,
                            t: t,
                            calm: calm,
                          ),
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
                        Positioned(
                          bottom: side * 0.04,
                          child: _figure(side * 0.42, t),
                        ),
                        if (widget.countdown != null) _countdown(side),
                      ],
                    );
                  case TimerStyle.hourglass:
                    return Stack(
                      children: [
                        CustomPaint(
                          size: size,
                          painter: HourglassPainter(
                            fraction: frac,
                            t: t,
                            calm: calm,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: side * 0.02,
                          child: _figure(side * 0.3, t),
                        ),
                        if (widget.countdown != null) _countdown(side),
                      ],
                    );
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// Farbe des Fortschritts (nur unterstützend; Zeit steht zusätzlich als Zahl und Form da).
  Color _ringColor(double frac) {
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
