import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/deps.dart';
import '../../app/perf_flags.dart';
import '../../domain/catalog.dart';
import '../../domain/session_plan.dart';
import '../../domain/timer_engine.dart';
import '../art/story/art_images.dart';
import '../art/story/story_scene.dart';
import '../painters/character_painter.dart';
import '../painters/scene_painter.dart';
import '../theme.dart';
import '../widgets/duration_sheet.dart';
import '../widgets/gate_dialog.dart';
import '../widgets/timer_stage.dart';
import 'parent_screen.dart';
import 'picker_screen.dart';

/// Auswahl unter Berücksichtigung von Free/Pro (z. B. nach Erstattung).
CharacterSpec effectiveCharacter(AppDeps d) {
  final c = characterById(d.settings.profile.characterId);
  return (c.pro && !d.isPro) ? characterById('dog') : c;
}

BackgroundSpec effectiveBackground(AppDeps d) {
  final b = backgroundById(d.settings.profile.backgroundId);
  return (b.pro && !d.isPro) ? backgroundById('meadow') : b;
}

TimerStyle effectiveStyle(AppDeps d) {
  final s = d.settings.profile.style;
  return (s.pro && !d.isPro) ? TimerStyle.circle : s;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> _t = ValueNotifier(0);
  Motif? _motif;
  String? _motifFor;
  final StoryController _story = StoryController();

  @override
  void initState() {
    super.initState();
    ArtImages.instance.ensureLoaded();
    _ticker = createTicker((d) {
      final t = d.inMicroseconds / 1e6;
      // Hintergrund nur ca. 12 Bilder/s – spart Akku, wirkt ruhig.
      if ((t * 12).floor() != (_t.value * 12).floor()) _t.value = t;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    _story.dispose();
    super.dispose();
  }

  Future<Motif> _resolveMotif(AppDeps d) async {
    final id = d.settings.profile.characterId;
    if (id.startsWith('photo:') && d.isPro) {
      final f = await d.motifs.fileFor(id.substring(6));
      if (f != null) return Motif.photo(f);
    }
    return Motif.character(effectiveCharacter(d));
  }

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([d.all, ArtImages.instance]),
      builder: (context, _) {
        final bg = effectiveBackground(d);
        // Illustrierte Story-Szene (Prototyp): Mira + Blumenwiese + Abenteuer-Timer
        final storyOn =
            ArtImages.instance.ready &&
            d.settings.profile.characterId == 'nova_mira' &&
            effectiveCharacter(d).id == 'nova_mira' &&
            bg.id == 'meadow' &&
            effectiveStyle(d) == TimerStyle.adventure;
        final calm =
            d.settings.calmMode || MediaQuery.of(context).disableAnimations;
        final timer = d.timer;
        final running = timer.isRunning || timer.isCountingDown;
        final locked = running && d.settings.lockWhileRunning;
        final id = d.settings.profile.characterId + d.isPro.toString();
        if (_motifFor != id) {
          _motifFor = id;
          _resolveMotif(d).then((m) {
            if (mounted && _motifFor == id) setState(() => _motif = m);
          });
        }
        final motif = _motif ?? Motif.character(effectiveCharacter(d));
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (storyOn)
                StoryScene(
                  engine: timer.engine,
                  controller: _story,
                  fraction: () => timer.displayFraction,
                  calm: calm,
                  breakPhase: timer.planView?.isPause ?? false,
                )
              else
                ValueListenableBuilder<double>(
                  valueListenable: _t,
                  builder: (_, t, _) => CustomPaint(
                    painter: ScenePainter(bg, t: t, calm: calm),
                  ),
                ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final landscape = c.maxWidth > c.maxHeight * 1.1;
                    final stage = storyOn
                        ? StoryStage(
                            controller: _story,
                            countdown: timer.countdown,
                            semanticsLabel: context.tr(
                              'Fortschritt',
                              'Progress',
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(12),
                            child: TimerStage(
                              engine: timer.engine,
                              style: effectiveStyle(d),
                              motif: motif,
                              calm: calm,
                              countdown: timer.countdown,
                              fraction: () => timer.displayFraction,
                              breakPhase: timer.planView?.isPause ?? false,
                              scenery: bg.scenery,
                            ),
                          );
                    final Widget controls = perfOff('ui')
                        ? const SizedBox(height: 300)
                        : _Controls(locked: locked);
                    final top = _TopBar(locked: locked);
                    if (landscape) {
                      return Column(
                        children: [
                          top,
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(flex: 5, child: stage),
                                Expanded(
                                  flex: 4,
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: controls,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    // Kleine Telefone: mehr Platz für die Bedienung, damit nichts abgeschnitten wird.
                    final compact = c.maxHeight < 700;
                    return Column(
                      children: [
                        top,
                        Expanded(flex: compact ? 4 : 6, child: stage),
                        Flexible(
                          flex: compact ? 6 : 5,
                          child: Center(
                            child: SingleChildScrollView(child: controls),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final spec = effectiveCharacter(d);
    final multi = d.settings.profiles.length > 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          if (!locked)
            _RoundButton(
              semantics: context.tr(
                'Figur und Welt wählen',
                'Choose character and world',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PickerScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: CharacterView(spec: spec),
              ),
            ),
          if (multi && !locked) ...[
            const SizedBox(width: 10),
            _Pill(
              icon: Icons.face_rounded,
              label: d.settings.profile.nickname,
              onTap: () => _switchProfile(context, d),
            ),
          ],
          const Spacer(),
          _RoundButton(
            semantics: d.settings.muted
                ? context.tr('Ton einschalten', 'Turn sound on')
                : context.tr('Ton ausschalten', 'Turn sound off'),
            onTap: () async {
              await d.settings.update((s) => s.muted = !s.muted);
              if (d.settings.muted) await d.audio.stopAll();
              await d.timer.applySettings();
              if (!d.settings.muted && d.timer.isRunning)
                await d.timer.changeMusic();
            },
            child: Icon(
              d.settings.muted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              size: 30,
              color: Brand.indigo,
            ),
          ),
          if (!locked) ...[
            const SizedBox(width: 10),
            _RoundButton(
              semantics: context.tr('Bereich für Eltern', 'Parents area'),
              onTap: () async {
                if (await requireParent(context) && context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ParentScreen(),
                    ),
                  );
                }
              },
              child: const Icon(
                Icons.lock_rounded,
                size: 28,
                color: Brand.indigo,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _switchProfile(BuildContext context, AppDeps d) async {
    final p = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in d.settings.profiles)
              ListTile(
                leading: SizedBox(
                  width: 44,
                  height: 44,
                  child: CharacterView(spec: characterById(p.characterId)),
                ),
                title: Text(
                  p.nickname,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                trailing: p.id == d.settings.activeProfileId
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                onTap: () => Navigator.pop(context, p.id),
              ),
          ],
        ),
      ),
    );
    if (p != null) await d.settings.update((s) => s.activeProfileId = p);
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.onTap,
    required this.semantics,
  });
  final Widget child;
  final VoidCallback onTap;
  final String semantics;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    child: Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 56, height: 56, child: Center(child: child)),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(28),
    elevation: 3,
    shadowColor: Colors.black26,
    child: InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Brand.indigo),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Controls extends StatelessWidget {
  const _Controls({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final timer = d.timer;
    final e = timer.engine;
    final status = e.status;
    final de = context.isDe;
    final pv = timer.planView;
    final String label;
    if (pv != null &&
        status != TimerStatus.finished &&
        status != TimerStatus.idle) {
      final phase = pv.isPause
          ? context.tr('Pause', 'Break')
          : context.tr(
              'Runde ${pv.round} von ${pv.rounds}',
              'Round ${pv.round} of ${pv.rounds}',
            );
      label = status == TimerStatus.paused
          ? context.tr('Angehalten · $phase', 'Paused · $phase')
          : phase;
    } else if (pv != null && status == TimerStatus.idle) {
      label = context.tr(
        'Lernen & Pausen · ${pv.rounds} Runden',
        'Study & breaks · ${pv.rounds} rounds',
      );
    } else {
      label = switch (status) {
        TimerStatus.idle => context.tr('Bereit', 'Ready'),
        TimerStatus.running => context.tr('Noch', 'Left'),
        TimerStatus.paused => context.tr('Pause', 'Paused'),
        TimerStatus.finished => context.tr('Geschafft!', 'All done!'),
      };
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Zeitanzeige – große Ziffern auf heller Fläche (Kontrast), zusätzlich gesprochene Beschreibung
          Builder(
            builder: (context) {
              final s = timer.displaySeconds;
              return Semantics(
                label: '$label ${spokenDuration(s, de)}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6B6485),
                        ),
                      ),
                      FittedBox(
                        child: Text(
                          formatClock(s),
                          style: const TextStyle(
                            fontSize: 64,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: Brand.ink,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (pv != null) ...[
            const SizedBox(height: 10),
            _PlanBar(view: pv, plan: timer.plan!, status: status),
          ],
          const SizedBox(height: 16),
          if (status == TimerStatus.finished)
            _finishedButtons(context, d)
          else
            _runButtons(context, d, locked),
          if (status == TimerStatus.idle && !locked) ...[
            const SizedBox(height: 14),
            if (pv == null) _QuickPicks() else _PlanChip(),
          ],
        ],
      ),
    );
  }

  Widget _finishedButtons(BuildContext context, AppDeps d) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BigButton(
          icon: Icons.replay_rounded,
          color: Brand.coral,
          semantics: context.tr('Noch einmal', 'Again'),
          onTap: () async {
            await d.timer.stop();
            await d.timer.start();
          },
        ),
        const SizedBox(width: 20),
        _BigButton(
          icon: Icons.check_rounded,
          color: Brand.mint,
          semantics: context.tr('Fertig', 'Done'),
          small: true,
          onTap: d.timer.stop,
        ),
      ],
    );
  }

  Widget _runButtons(BuildContext context, AppDeps d, bool locked) {
    final t = d.timer;
    final running = t.isRunning || t.isCountingDown;
    final paused = t.status == TimerStatus.paused;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!locked && t.status == TimerStatus.idle)
          _BigButton(
            icon: Icons.timer_outlined,
            color: Brand.indigo,
            small: true,
            semantics: context.tr('Zeit ändern', 'Change time'),
            onTap: () => showDurationSheet(context),
          ),
        if (!locked && t.status == TimerStatus.idle) const SizedBox(width: 20),
        _BigButton(
          icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Brand.coral,
          semantics: running
              ? context.tr('Pause', 'Pause')
              : (paused
                    ? context.tr('Weiter', 'Resume')
                    : context.tr('Start', 'Start')),
          onTap: t.togglePlayPause,
        ),
        if (running || paused) const SizedBox(width: 20),
        if (running || paused)
          _BigButton(
            icon: Icons.stop_rounded,
            color: Brand.indigo,
            small: true,
            semantics: locked
                ? context.tr(
                    'Timer beenden (Erwachsene)',
                    'Stop timer (grown-ups)',
                  )
                : context.tr('Stopp', 'Stop'),
            onTap: () async {
              if (locked &&
                  !await requireParent(
                    context,
                    reason: context.tr(
                      'Timer wirklich beenden?',
                      'Really stop the timer?',
                    ),
                  ))
                return;
              await t.stop();
            },
          ),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.semantics,
    this.small = false,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String semantics;
  final bool small;
  @override
  Widget build(BuildContext context) {
    final size = small ? 72.0 : 104.0;
    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 4),
        ),
        elevation: 6,
        shadowColor: Colors.black38,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.55, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _QuickPicks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final cur = d.timer.engine.totalMs ~/ 60000;
    final exact = d.timer.engine.totalMs % 60000 == 0;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final m in quickMinutes)
          Semantics(
            button: true,
            selected: exact && cur == m,
            label: spokenDuration(m * 60, context.isDe),
            excludeSemantics: true,
            child: Material(
              color: exact && cur == m
                  ? Brand.indigo
                  : Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => d.timer.setDuration(Duration(minutes: m)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(
                        '$m',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: exact && cur == m ? Colors.white : Brand.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Text(
            'Min',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.95),
              shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
            ),
          ),
        ),
      ],
    );
  }
}

/// Plan-Übersicht: ein Segment je Phase. Breite = Dauer; Arbeit = Balken, Pause = Kreis.
/// Fertig = gefüllt, laufend = teilweise gefüllt mit Rahmen, offen = leer (Zustand auch ohne Farbe lesbar).
class _PlanBar extends StatelessWidget {
  const _PlanBar({
    required this.view,
    required this.plan,
    required this.status,
  });
  final PlanView view;
  final SessionPlan plan;
  final TimerStatus status;

  @override
  Widget build(BuildContext context) {
    final total = plan.totalMs;
    return Semantics(
      label: context.tr(
        'Plan: Runde ${view.round} von ${view.rounds}, ${view.isPause ? 'Pause läuft' : 'Arbeitsphase läuft'}',
        'Plan: round ${view.round} of ${view.rounds}, ${view.isPause ? 'break running' : 'work phase running'}',
      ),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
        ),
        // Breite folgt den Phasendauern; bei vielen Runden wird die Leiste verkleinert statt abgeschnitten.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < plan.steps.length; i++) ...[
                _segment(
                  i,
                  plan.steps[i],
                  (240.0 * plan.steps[i].ms / total).clamp(
                    plan.steps[i].kind == StepKind.pause ? 14.0 : 22.0,
                    120.0,
                  ),
                ),
                if (i < plan.steps.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _segment(int i, PlanStep s, double w) {
    final done = status == TimerStatus.finished || i < view.index;
    final current =
        i == view.index &&
        status != TimerStatus.finished &&
        status != TimerStatus.idle;
    final fill = done ? 1.0 : (current ? 1 - view.stepFraction : 0.0);
    final color = s.kind == StepKind.pause
        ? const Color(0xFF5BA8F0)
        : Brand.mint;
    final shape = s.kind == StepKind.pause
        ? BoxShape.circle
        : BoxShape.rectangle;
    final size = s.kind == StepKind.pause ? 14.0 : 14.0;
    return Container(
      width: s.kind == StepKind.pause ? size : w,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(7),
        border: Border.all(
          color: current ? Brand.indigo : const Color(0xFFB8B2CC),
          width: current ? 2.5 : 1.5,
        ),
        color: const Color(0xFFF1EEF8),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fill,
        heightFactor: 1,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// Zeigt im Leerlauf den aktiven Plan und erlaubt, ihn zu entfernen.
class _PlanChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final p = d.timer.plan!;
    final focus =
        p.steps.firstWhere((s) => s.kind == StepKind.focus).ms ~/ 60000;
    final pauses = p.steps.where((s) => s.kind == StepKind.pause).toList();
    final pause = pauses.isEmpty ? 0 : pauses.first.ms ~/ 60000;
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                context.tr(
                  '${p.rounds} × $focus Min.${pause > 0 ? ' · Pause $pause Min.' : ''}',
                  '${p.rounds} × $focus min${pause > 0 ? ' · break $pause min' : ''}',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            IconButton(
              tooltip: context.tr('Plan entfernen', 'Remove plan'),
              icon: const Icon(Icons.close_rounded),
              onPressed: () => d.timer.setPlan(null),
            ),
          ],
        ),
      ),
    );
  }
}
