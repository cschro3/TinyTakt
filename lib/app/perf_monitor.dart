import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'perf_export_stub.dart'
    if (dart.library.js_interop) 'perf_export_web.dart';

/// Misst, wie viele Bilder die App tatsächlich liefert (Rhythmus der Frame-Callbacks),
/// wie lange einzelne Bildteile in Dart brauchen und wann die Szene fertig war.
///
/// Zweck: (1) die adaptive Qualitätsstufe der Szene (siehe `StoryGovernor`),
/// (2) ein Overlay mit `?perf=1` für Messungen auf echten Geräten,
/// (3) Export nach `window.__ttPerf` für automatisierte Browser-Messungen.
/// Es werden keine Daten gesendet.
class PerfMonitor {
  PerfMonitor._();
  static final PerfMonitor instance = PerfMonitor._();

  final Stopwatch _clock = Stopwatch()..start();
  final List<int> _frameStampsUs = [];
  bool _observing = false;
  Timer? _publisher;
  final Map<String, List<int>> _costs = {};
  final Map<String, double> marks = {};
  final ValueNotifier<String> hudText = ValueNotifier('');
  String tier = '-';
  int rateHz = 0;
  double textureMB = 0;

  /// Overlay/Export aktiv (`?perf=1` oder `--dart-define=PERF_HUD=true`).
  late final bool hudEnabled =
      const bool.fromEnvironment('PERF_HUD') || perfRequestedByUrl();

  /// Feste Qualitätsstufe für Messungen (`?tier=…` oder `--dart-define=PERF_TIER=…`), sonst null.
  late final String? forcedTier = () {
    const d = String.fromEnvironment('PERF_TIER');
    final v = d.isNotEmpty ? d : perfTierByUrl();
    return (v == 'full' || v == 'reduced' || v == 'minimal') ? v : null;
  }();

  int get _nowUs => _clock.elapsedMicroseconds;

  /// Beginnt, Frame-Zeitpunkte aufzuzeichnen (idempotent, ohne Frames anzufordern).
  void start() {
    if (_observing) return;
    _observing = true;
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
    if (hudEnabled) {
      _publisher ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _publish(),
      );
    }
  }

  void _onFrame(Duration _) {
    if (!_observing) return;
    final now = _nowUs;
    _frameStampsUs.add(now);
    while (_frameStampsUs.isNotEmpty && now - _frameStampsUs.first > 8000000) {
      _frameStampsUs.removeAt(0);
    }
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  /// Bilder pro Sekunde im Mittel der letzten [seconds] Sekunden (0, wenn keine Frames kamen).
  double achievedFps({double seconds = 2}) {
    final now = _nowUs;
    final from = now - (seconds * 1e6).round();
    var n = 0;
    for (
      var i = _frameStampsUs.length - 1;
      i >= 0 && _frameStampsUs[i] >= from;
      i--
    ) {
      n++;
    }
    return n / seconds;
  }

  /// Abstände zwischen den letzten Frames in ms (sortiert).
  List<double> recentIntervalsMs() {
    final out = <double>[];
    for (var i = 1; i < _frameStampsUs.length; i++) {
      out.add((_frameStampsUs[i] - _frameStampsUs[i - 1]) / 1000);
    }
    out.sort();
    return out;
  }

  /// Dart-Kosten eines Bildteils (Aufzeichnung, ohne GPU) festhalten.
  void cost(String key, int micros) {
    if (!hudEnabled) return;
    final l = _costs.putIfAbsent(key, () => <int>[]);
    l.add(micros);
    if (l.length > 240) l.removeAt(0);
  }

  void mark(String name) {
    marks.putIfAbsent(name, () => _clock.elapsedMilliseconds.toDouble());
  }

  /// Dauer zwischen zwei Marken in ms (oder null).
  double? span(String from, String to) {
    final a = marks[from], b = marks[to];
    return (a == null || b == null) ? null : b - a;
  }

  Map<String, Object?> snapshot() {
    final iv = recentIntervalsMs();
    double q(double p) => iv.isEmpty ? 0 : iv[((iv.length - 1) * p).round()];
    return {
      'fps': double.parse(achievedFps(seconds: 3).toStringAsFixed(1)),
      'p50ms': double.parse(q(.5).toStringAsFixed(1)),
      'p95ms': double.parse(q(.95).toStringAsFixed(1)),
      'tier': tier,
      'rateHz': rateHz,
      'textureMB': double.parse(textureMB.toStringAsFixed(1)),
      'marks': marks,
      'ladeBisSzeneMs': span('homeInit', 'staticReady'),
      'pageNowMs': pageNowMs(),
      'costMeanUs': {
        for (final e in _costs.entries)
          e.key: (e.value.reduce((a, b) => a + b) / e.value.length).round(),
      },
    };
  }

  void _publish() {
    final s = snapshot();
    publishPerf(jsonEncode(s));
    final cost = (s['costMeanUs'] as Map).entries
        .map((e) => '${e.key} ${(e.value as int) / 1000}ms')
        .join(' · ');
    hudText.value =
        '${s['fps']} fps · p95 ${s['p95ms']} ms · ${s['tier']} @${s['rateHz']} Hz\n'
        'Tex ${s['textureMB']} MB · $cost\n'
        '${marks.entries.map((e) => '${e.key} ${e.value.round()}ms').join(' · ')}';
  }
}

/// Kleines Mess-Overlay (nur mit `?perf=1` sichtbar).
class PerfHud extends StatelessWidget {
  const PerfHud({super.key});

  @override
  Widget build(BuildContext context) {
    final m = PerfMonitor.instance;
    if (!m.hudEnabled) return const SizedBox.shrink();
    m.start();
    return Positioned(
      left: 6,
      top: 70,
      child: IgnorePointer(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: RepaintBoundary(
            child: ValueListenableBuilder<String>(
              valueListenable: m.hudText,
              builder: (_, text, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xCC000000),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    height: 1.25,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
