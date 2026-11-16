import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../data/settings_repository.dart';
import '../../domain/session_plan.dart';
import '../screens/pro_screen.dart';
import '../theme.dart';
import '../widgets/gate_dialog.dart';

/// Frei einstellbare Dauer (Stunden, Minuten, Sekunden) – nur im Leerlauf.
Future<void> showDurationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => const _DurationSheet(),
  );
}

class _DurationSheet extends StatefulWidget {
  const _DurationSheet();
  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  int h = 0, m = 5, s = 0;
  bool _init = false;
  bool _planMode = false;
  int _focus = 15, _pause = 5, _rounds = 3;
  static const _focusValues = [5, 10, 15, 20, 25, 30, 45, 60];
  static const _pauseValues = [1, 2, 3, 5, 10, 15];
  late FixedExtentScrollController _hc, _mc, _sc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final timer = AppScope.of(context).timer;
    final plan = timer.plan;
    if (plan != null) {
      _planMode = true;
      _rounds = plan.rounds;
      _focus =
          plan.steps.firstWhere((x) => x.kind == StepKind.focus).ms ~/ 60000;
      final pauses = plan.steps.where((x) => x.kind == StepKind.pause);
      _pause = pauses.isEmpty ? 0 : pauses.first.ms ~/ 60000;
    }
    final total = (plan != null
        ? Duration(seconds: AppScope.of(context).settings.lastSeconds).inSeconds
        : timer.engine.totalMs ~/ 1000);
    h = total ~/ 3600;
    m = (total % 3600) ~/ 60;
    s = total % 60;
    _hc = FixedExtentScrollController(initialItem: h);
    _mc = FixedExtentScrollController(initialItem: m);
    _sc = FixedExtentScrollController(initialItem: s);
  }

  @override
  void dispose() {
    _hc.dispose();
    _mc.dispose();
    _sc.dispose();
    super.dispose();
  }

  int get _total => h * 3600 + m * 60 + s;

  Widget _wheel(
    FixedExtentScrollController c,
    int count,
    String label,
    ValueChanged<int> on,
  ) {
    return Expanded(
      child: Semantics(
        label: label,
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B6485),
              ),
            ),
            SizedBox(
              height: 150,
              child: CupertinoPicker(
                scrollController: c,
                itemExtent: 48,
                magnification: 1.15,
                useMagnifier: true,
                onSelectedItemChanged: (i) => setState(() => on(i)),
                children: [
                  for (var i = 0; i < count; i++)
                    Center(
                      child: Text(
                        i.toString().padLeft(2, '0'),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D4E8),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('Wie lange?', 'How long?'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    icon: const Icon(Icons.timer_outlined),
                    label: Text(context.tr('Einzeln', 'Single')),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.repeat_rounded),
                    label: Text(
                      context.tr('Lernen & Pausen', 'Study & breaks'),
                    ),
                  ),
                ],
                selected: {_planMode},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _planMode = v.first),
              ),
              const SizedBox(height: 8),
              if (_planMode)
                ..._planChildren(context, deps)
              else ...[
                Row(
                  children: [
                    _wheel(_hc, 24, context.tr('Std.', 'Hrs'), (i) => h = i),
                    _wheel(_mc, 60, context.tr('Min.', 'Min'), (i) => m = i),
                    _wheel(_sc, 60, context.tr('Sek.', 'Sec'), (i) => s = i),
                  ],
                ),
                if (deps.settings.templates.isNotEmpty || deps.isPro) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in deps.settings.templates)
                        ActionChip(
                          avatar: const Icon(Icons.bookmark_rounded, size: 18),
                          label: Text('${t.name} · ${formatClock(t.seconds)}'),
                          onPressed: () {
                            deps.timer.setDuration(
                              Duration(seconds: t.seconds),
                            );
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: Text(context.tr('Als Vorlage', 'Save template')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _total == 0
                            ? null
                            : () => _saveTemplate(context, deps),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _total == 0
                            ? null
                            : () async {
                                await deps.timer.setDuration(
                                  Duration(seconds: _total),
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                        child: Text(context.tr('Fertig', 'Done')),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper(
    BuildContext context,
    String label,
    String value,
    VoidCallback? minus,
    VoidCallback? plus,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton.filledTonal(
            tooltip: context.tr('Weniger: $label', 'Less: $label'),
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            onPressed: minus,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 92,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton.filledTonal(
            tooltip: context.tr('Mehr: $label', 'More: $label'),
            iconSize: 28,
            constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
            onPressed: plus,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  int _step(List<int> values, int cur, int dir) {
    var i = values.indexWhere((v) => v >= cur);
    if (i < 0) i = values.length - 1;
    return values[(i + dir).clamp(0, values.length - 1)];
  }

  List<Widget> _planChildren(BuildContext context, AppDeps deps) {
    final plan = SessionPlan.rounds(
      focusMin: _focus,
      pauseMin: _pause,
      rounds: _rounds,
    );
    final pauses = _rounds - 1;
    final presets = [
      (context.tr('Hausaufgaben', 'Homework'), 15, 5, 3),
      (context.tr('Lesen', 'Reading'), 20, 5, 2),
      (context.tr('Aufräumen', 'Tidying up'), 5, 1, 3),
      (context.tr('Spielen', 'Playing'), 10, 2, 2),
    ];
    final summary = context.tr(
      '$_rounds × $_focus Min.${pauses > 0 && _pause > 0 ? ' + $pauses × $_pause Min. Pause' : ''} = ${plan.totalMs ~/ 60000} Min. insgesamt',
      '$_rounds × $_focus min${pauses > 0 && _pause > 0 ? ' + $pauses × $_pause min break' : ''} = ${plan.totalMs ~/ 60000} min in total',
    );
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.tr(
            'Arbeiten und Ausruhen im Wechsel – der Timer läuft von allein weiter.',
            'Work and rest in turns – the timer carries on by itself.',
          ),
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B6485)),
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in presets)
            ActionChip(
              label: Text('${p.$1} · ${p.$2}+${p.$3} ×${p.$4}'),
              onPressed: () => setState(() {
                _focus = p.$2;
                _pause = p.$3;
                _rounds = p.$4;
              }),
            ),
        ],
      ),
      const SizedBox(height: 8),
      _stepper(
        context,
        context.tr('Arbeiten', 'Work'),
        context.tr('$_focus Min.', '$_focus min'),
        _focus > _focusValues.first
            ? () => setState(() => _focus = _step(_focusValues, _focus, -1))
            : null,
        _focus < _focusValues.last
            ? () => setState(() => _focus = _step(_focusValues, _focus, 1))
            : null,
      ),
      _stepper(
        context,
        context.tr('Pause', 'Break'),
        _pause == 0
            ? context.tr('keine', 'none')
            : context.tr('$_pause Min.', '$_pause min'),
        _pause > 0
            ? () => setState(
                () => _pause = _pause == _pauseValues.first
                    ? 0
                    : _step(_pauseValues, _pause, -1),
              )
            : null,
        _pause < _pauseValues.last
            ? () => setState(
                () => _pause = _pause == 0
                    ? _pauseValues.first
                    : _step(_pauseValues, _pause, 1),
              )
            : null,
      ),
      _stepper(
        context,
        context.tr('Runden', 'Rounds'),
        '$_rounds',
        _rounds > 1 ? () => setState(() => _rounds--) : null,
        _rounds < 8 ? () => setState(() => _rounds++) : null,
      ),
      const SizedBox(height: 8),
      Semantics(
        liveRegion: true,
        child: Text(
          summary,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          if (deps.timer.plan != null) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () async {
                  await deps.timer.setPlan(null);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(context.tr('Plan entfernen', 'Remove plan')),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              onPressed: plan.isValid
                  ? () async {
                      await deps.timer.setPlan(plan);
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              child: Text(context.tr('Plan übernehmen', 'Use plan')),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _saveTemplate(BuildContext context, AppDeps deps) async {
    if (!deps.isPro) {
      Navigator.pop(context);
      await openPro(context);
      return;
    }
    if (!await requireParent(context)) return;
    if (!context.mounted) return;
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('Name der Vorlage', 'Template name')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            hintText: context.tr('z. B. Zähneputzen', 'e.g. Brushing teeth'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: Text(context.tr('Speichern', 'Save')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await deps.settings.addTemplate(
      TimerTemplate(
        id: 't${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        seconds: _total,
      ),
      isPro: deps.isPro,
    );
    if (context.mounted) setState(() {});
  }
}
