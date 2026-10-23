import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/deps.dart';
import '../../app/info.dart';
import '../../data/parental_gate.dart';
import '../../domain/catalog.dart';
import '../theme.dart';
import 'legal_screen.dart';
import 'pro_screen.dart';

/// Elternbereich – wird nur nach bestandener Elternsicherung geöffnet.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Für Eltern', 'For parents'))),
      body: ListenableBuilder(
        listenable: d.all,
        builder: (context, _) {
          final s = d.settings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _ProCard(),
              _Section(context.tr('Timer', 'Timer'), [
                SwitchListTile(
                  title: Text(context.tr('Timer wiederholen', 'Repeat timer')),
                  subtitle: Text(
                    context.tr(
                      'Startet nach dem Ende automatisch neu.',
                      'Restarts automatically when finished.',
                    ),
                  ),
                  value: s.repeat,
                  onChanged: (v) async {
                    await s.update((x) => x.repeat = v);
                    await d.timer.applySettings();
                  },
                ),
                SwitchListTile(
                  title: Text(
                    context.tr('Kindermodus-Sperre', 'Child mode lock'),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Während ein Timer läuft, sind Einstellungen verborgen; Beenden braucht die Elternsicherung.',
                      'While a timer runs, settings are hidden; stopping needs the parental gate.',
                    ),
                  ),
                  value: s.lockWhileRunning,
                  onChanged: (v) => s.update((x) => x.lockWhileRunning = v),
                ),
                SwitchListTile(
                  title: Text(
                    context.tr('Bildschirm anlassen', 'Keep screen on'),
                  ),
                  value: s.keepScreenOn,
                  onChanged: (v) => s.update((x) => x.keepScreenOn = v),
                ),
                SwitchListTile(
                  title: Text(context.tr('Ruhiger Modus', 'Calm mode')),
                  subtitle: Text(
                    context.tr(
                      'Keine bewegten Figuren, keine Musik, kein Konfetti.',
                      'No moving characters, no music, no confetti.',
                    ),
                  ),
                  value: s.calmMode,
                  onChanged: (v) async {
                    await s.update((x) => x.calmMode = v);
                    if (v) await d.audio.stopAll();
                  },
                ),
              ]),
              _Section(context.tr('Ton', 'Sound'), [
                SwitchListTile(
                  title: Text(context.tr('Stumm', 'Muted')),
                  value: s.muted,
                  onChanged: (v) async {
                    await s.update((x) => x.muted = v);
                    if (v) await d.audio.stopAll();
                  },
                ),
                _VolumeTile(
                  label: context.tr('Musik-Lautstärke', 'Music volume'),
                  value: s.musicVolume,
                  onChanged: (v) async {
                    await s.update((x) => x.musicVolume = v);
                    await d.audio.setMusicVolume(v);
                  },
                ),
                _VolumeTile(
                  label: context.tr('Alarm-Lautstärke', 'Alarm volume'),
                  value: s.alarmVolume,
                  onChanged: (v) => s.update((x) => x.alarmVolume = v),
                ),
                SwitchListTile(
                  title: Text(context.tr('Countdown 3-2-1', 'Countdown 3-2-1')),
                  value: s.countdown321,
                  onChanged: (v) => s.update((x) => x.countdown321 = v),
                ),
                SwitchListTile(
                  title: Text(
                    context.tr(
                      'Sprachausgabe am Ende',
                      'Spoken message at the end',
                    ),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Nutzt die Sprachausgabe des Geräts.',
                      'Uses the device text-to-speech.',
                    ),
                  ),
                  value: s.speech,
                  onChanged: (v) => s.update((x) => x.speech = v),
                ),
                for (final a in sounds.where((x) => x.kind == SoundKind.alarm))
                  ListTile(
                    title: Text(context.isDe ? a.de : a.en),
                    leading: Icon(
                      s.alarmId == a.id
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: Brand.indigo,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a.pro && !d.isPro)
                          const Icon(Icons.lock_rounded, color: Brand.coral),
                        IconButton(
                          tooltip: context.tr('Anhören', 'Listen'),
                          icon: const Icon(Icons.play_circle_rounded),
                          onPressed: () => d.audio.playAlarm(a, s.alarmVolume),
                        ),
                      ],
                    ),
                    onTap: () => a.pro && !d.isPro
                        ? openPro(context)
                        : s.update((x) => x.alarmId = a.id),
                  ),
              ]),
              _Section(
                context.tr('Kinderprofile (lokal)', 'Child profiles (local)'),
                [
                  for (final p in s.profiles)
                    ListTile(
                      leading: Icon(
                        p.id == s.activeProfileId
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: Brand.indigo,
                      ),
                      title: Text(p.nickname),
                      subtitle: Text(
                        context.tr(
                          'Spitzname – kein echter Name nötig',
                          'Nickname – no real name needed',
                        ),
                      ),
                      trailing: s.profiles.length > 1
                          ? IconButton(
                              tooltip: context.tr('Löschen', 'Delete'),
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () => s.removeProfile(p.id),
                            )
                          : null,
                      onTap: () => s.update((x) => x.activeProfileId = p.id),
                    ),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt_1_rounded),
                    title: Text(context.tr('Profil hinzufügen', 'Add profile')),
                    trailing: d.isPro
                        ? null
                        : const Icon(Icons.lock_rounded, color: Brand.coral),
                    onTap: () async {
                      if (!d.isPro) return openPro(context);
                      final name = await _ask(
                        context,
                        context.tr('Spitzname', 'Nickname'),
                      );
                      if (name != null)
                        await s.addProfile(name, isPro: d.isPro);
                    },
                  ),
                ],
              ),
              _Section(context.tr('Timer-Vorlagen', 'Timer templates'), [
                if (s.templates.isEmpty)
                  ListTile(
                    title: Text(
                      d.isPro
                          ? context.tr(
                              'Noch keine Vorlagen. Lege sie über „Zeit ändern“ an.',
                              'No templates yet. Create them via “Change time”.',
                            )
                          : context.tr(
                              'Eigene Vorlagen gibt es mit Pro.',
                              'Custom templates come with Pro.',
                            ),
                    ),
                    trailing: d.isPro
                        ? null
                        : const Icon(Icons.lock_rounded, color: Brand.coral),
                    onTap: d.isPro ? null : () => openPro(context),
                  ),
                for (final t in s.templates)
                  ListTile(
                    leading: const Icon(Icons.bookmark_rounded),
                    title: Text(t.name),
                    subtitle: Text(formatClock(t.seconds)),
                    trailing: IconButton(
                      tooltip: context.tr('Löschen', 'Delete'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => s.removeTemplate(t.id),
                    ),
                  ),
              ]),
              _Section(context.tr('Eigene Fotos (Pro)', 'Your photos (Pro)'), [
                ListTile(
                  title: Text(
                    context.tr(
                      'Foto als Timer-Motiv hinzufügen',
                      'Add photo as timer picture',
                    ),
                  ),
                  subtitle: Text(
                    context.tr(
                      'Wird nur lokal gespeichert. Keine Fotoberechtigung nötig.',
                      'Stored locally only. No photo permission needed.',
                    ),
                  ),
                  leading: const Icon(Icons.add_photo_alternate_rounded),
                  trailing: d.isPro
                      ? null
                      : const Icon(Icons.lock_rounded, color: Brand.coral),
                  onTap: () async {
                    if (!d.isPro) return openPro(context);
                    try {
                      final name = await d.motifs.pickAndStore();
                      if (name != null)
                        await s.update(
                          (x) => x.customMotifs = [...x.customMotifs, name],
                        );
                    } on PlatformException {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr(
                                'Das Foto konnte nicht geladen werden.',
                                'The photo could not be loaded.',
                              ),
                            ),
                          ),
                        );
                    }
                  },
                ),
                for (var i = 0; i < s.customMotifs.length; i++)
                  ListTile(
                    leading: const Icon(Icons.photo_rounded),
                    title: Text(context.tr('Foto ${i + 1}', 'Photo ${i + 1}')),
                    trailing: IconButton(
                      tooltip: context.tr('Foto löschen', 'Delete photo'),
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final name = s.customMotifs[i];
                        await d.motifs.delete(name);
                        await s.update((x) {
                          x.customMotifs = x.customMotifs
                              .where((e) => e != name)
                              .toList();
                        });
                        for (final p in s.profiles) {
                          if (p.characterId == 'photo:$name') {
                            s.activeProfileId = p.id;
                            await s.updateProfile(
                              (q) => q.copyWith(characterId: 'dog'),
                            );
                          }
                        }
                      },
                    ),
                  ),
              ]),
              _Section(context.tr('Sicherheit', 'Security'), [_PinTile()]),
              _Section(context.tr('Information', 'Information'), [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_rounded),
                  title: Text(
                    context.tr('Datenschutzinformation', 'Privacy information'),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.business_rounded),
                  title: Text(
                    context.tr('Anbieterinformation', 'Provider information'),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ImprintScreen(),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text(context.tr('Support', 'Support')),
                  subtitle: const SelectableText(supportEmailPlaceholder),
                ),
                ListTile(
                  leading: const Icon(Icons.description_rounded),
                  title: Text(
                    context.tr(
                      'Lizenzen (Open Source)',
                      'Licences (open source)',
                    ),
                  ),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'TinyTakt',
                    applicationVersion: appVersion,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.info_rounded),
                  title: const Text('TinyTakt'),
                  subtitle: Text(
                    '${context.tr('Version', 'Version')} $appVersion',
                  ),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  static Future<String?> _ask(BuildContext context, String title) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, maxLength: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: Text(context.tr('OK', 'OK')),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Brand.indigo,
              ),
            ),
          ),
        ),
        Card(child: Column(children: children)),
      ],
    ),
  );
}

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Slider(
      value: value,
      onChanged: onChanged,
      semanticFormatterCallback: (v) => '${(v * 100).round()} %',
    ),
  );
}

class _ProCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return Card(
      color: d.isPro ? const Color(0xFFE2F7F1) : Brand.indigo,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          d.isPro ? Icons.verified_rounded : Icons.star_rounded,
          color: d.isPro ? const Color(0xFF1FA48B) : Brand.sun,
          size: 36,
        ),
        title: Text(
          d.isPro
              ? context.tr('TinyTakt Pro ist aktiv', 'TinyTakt Pro is active')
              : context.tr('TinyTakt Pro', 'TinyTakt Pro'),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: d.isPro ? Brand.ink : Colors.white,
          ),
        ),
        subtitle: Text(
          d.isPro
              ? context.tr(
                  'Kauf verwalten und wiederherstellen',
                  'Manage and restore purchase',
                )
              : context.tr(
                  'Einmalig, ohne Abo – alle Figuren und Welten',
                  'One-time, no subscription – all characters and worlds',
                ),
          style: TextStyle(color: d.isPro ? Brand.ink : Colors.white70),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: d.isPro ? Brand.ink : Colors.white,
        ),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const ProScreen())),
      ),
    );
  }
}

class _PinTile extends StatefulWidget {
  @override
  State<_PinTile> createState() => _PinTileState();
}

class _PinTileState extends State<_PinTile> {
  bool? _has;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final h = await AppScope.of(context).gate.hasPin();
    if (mounted) setState(() => _has = h);
  }

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.pin_rounded),
          title: Text(
            _has == true
                ? context.tr('Eltern-PIN ändern', 'Change parent PIN')
                : context.tr(
                    'Eltern-PIN festlegen (optional)',
                    'Set parent PIN (optional)',
                  ),
          ),
          subtitle: Text(
            context.tr(
              'Ersetzt die Rechenaufgabe. Wird nur als Hash auf diesem Gerät gespeichert.',
              'Replaces the maths question. Stored only as a hash on this device.',
            ),
          ),
          onTap: () async {
            final pin = await _askPin(context, d.gate);
            if (pin != null) {
              await d.gate.setPin(pin);
              await _refresh();
            }
          },
        ),
        if (_has == true)
          ListTile(
            leading: const Icon(Icons.no_encryption_gmailerrorred_rounded),
            title: Text(
              context.tr('Eltern-PIN entfernen', 'Remove parent PIN'),
            ),
            onTap: () async {
              await d.gate.removePin();
              await _refresh();
            },
          ),
      ],
    );
  }

  Future<String?> _askPin(BuildContext context, ParentalGateService gate) {
    final a = TextEditingController(), b = TextEditingController();
    String? err;
    return showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          title: Text(
            context.tr('Neuer PIN (4–6 Ziffern)', 'New PIN (4–6 digits)'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: a,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: context.tr('PIN', 'PIN'),
                ),
              ),
              TextField(
                controller: b,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: context.tr('PIN wiederholen', 'Repeat PIN'),
                  errorText: err,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (!ParentalGateService.isValidPinFormat(a.text) ||
                    a.text != b.text) {
                  set(
                    () => err = context.tr(
                      'PINs müssen gleich sein (4–6 Ziffern).',
                      'PINs must match (4–6 digits).',
                    ),
                  );
                  return;
                }
                Navigator.pop(context, a.text);
              },
              child: Text(context.tr('Speichern', 'Save')),
            ),
          ],
        ),
      ),
    );
  }
}
