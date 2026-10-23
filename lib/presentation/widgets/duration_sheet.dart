import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../data/settings_repository.dart';
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
  late FixedExtentScrollController _hc, _mc, _sc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final total = AppScope.of(context).timer.engine.totalMs ~/ 1000;
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
                          deps.timer.setDuration(Duration(seconds: t.seconds));
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
          ),
        ),
      ),
    );
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
