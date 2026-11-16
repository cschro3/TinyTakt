/// Lern-/Spielzeit: Arbeits- und Pausenphasen nacheinander.
///
/// Der Plan ist reine Daten- und Rechenlogik. Die Zeit selbst läuft weiter in
/// der [TimerEngine] (Gesamtdauer = Summe aller Phasen); aus der verstrichenen
/// Gesamtzeit wird hier abgeleitet, in welcher Phase man sich befindet. Dadurch
/// gelten Pause/Fortsetzen, Hintergrund und Neustart-Wiederherstellung unverändert.
enum StepKind { focus, pause }

class PlanStep {
  const PlanStep(this.kind, this.ms);
  final StepKind kind;
  final int ms;
}

/// Momentaufnahme: wo im Plan befindet sich die verstrichene Zeit?
class PlanView {
  const PlanView({
    required this.index,
    required this.step,
    required this.stepRemainingMs,
    required this.round,
    required this.rounds,
    required this.finished,
  });

  final int index;
  final PlanStep step;
  final int stepRemainingMs;

  /// 1-basierte Runde (Anzahl Arbeitsphasen bis einschließlich der aktuellen).
  final int round;
  final int rounds;
  final bool finished;

  double get stepFraction =>
      step.ms <= 0 ? 0 : (stepRemainingMs / step.ms).clamp(0.0, 1.0);
  bool get isPause => step.kind == StepKind.pause;
}

class SessionPlan {
  const SessionPlan(this.steps);

  static const maxSteps = 24;
  static const minStepMs = 10 * 1000;
  static const maxStepMs = 4 * 60 * 60 * 1000;

  final List<PlanStep> steps;

  /// [rounds] Arbeitsphasen à [focusMin], dazwischen je [pauseMin] Pause (keine Pause nach der letzten Runde).
  factory SessionPlan.rounds({
    required int focusMin,
    required int pauseMin,
    required int rounds,
  }) {
    final list = <PlanStep>[];
    for (var r = 1; r <= rounds; r++) {
      list.add(PlanStep(StepKind.focus, focusMin * 60000));
      if (r < rounds && pauseMin > 0)
        list.add(PlanStep(StepKind.pause, pauseMin * 60000));
    }
    return SessionPlan(list);
  }

  bool get isValid =>
      steps.isNotEmpty &&
      steps.length <= maxSteps &&
      steps.every((s) => s.ms >= minStepMs && s.ms <= maxStepMs) &&
      steps.first.kind == StepKind.focus;

  int get totalMs => steps.fold(0, (a, s) => a + s.ms);
  int get rounds => steps.where((s) => s.kind == StepKind.focus).length;

  /// Ende jeder Phase, gemessen ab Planstart (kumuliert).
  List<int> get boundariesMs {
    var acc = 0;
    return [for (final s in steps) acc += s.ms];
  }

  PlanView viewAt(int elapsedMs) {
    final total = totalMs;
    final e = elapsedMs.clamp(0, total);
    var start = 0;
    var round = 0;
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.kind == StepKind.focus) round++;
      final end = start + s.ms;
      final last = i == steps.length - 1;
      if (e < end || last) {
        return PlanView(
          index: i,
          step: s,
          stepRemainingMs: (end - e).clamp(0, s.ms),
          round: round,
          rounds: rounds,
          finished: e >= total,
        );
      }
      start = end;
    }
    throw StateError('leerer Plan');
  }

  Map<String, Object?> toJson() => {
    'steps': [
      for (final s in steps) {'k': s.kind.name, 'ms': s.ms},
    ],
  };

  static SessionPlan? tryFromJson(Object? m) {
    if (m is! Map) return null;
    final raw = m['steps'];
    if (raw is! List) return null;
    final steps = <PlanStep>[];
    for (final e in raw) {
      if (e is! Map) return null;
      final kind = StepKind.values.where((k) => k.name == e['k']);
      final ms = e['ms'];
      if (kind.isEmpty || ms is! int) return null;
      steps.add(PlanStep(kind.first, ms));
    }
    final plan = SessionPlan(steps);
    return plan.isValid ? plan : null;
  }
}
