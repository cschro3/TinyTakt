import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../platform/apple_music_service.dart';
import '../theme.dart';

/// Wählt einen Apple-Music-Titel als Timer-Musik. Nur über den Elternbereich erreichbar
/// (also hinter der Elternsicherung); Kinder können hier nie suchen.
class AppleMusicSearchScreen extends StatefulWidget {
  const AppleMusicSearchScreen({super.key});
  @override
  State<AppleMusicSearchScreen> createState() => _AppleMusicSearchScreenState();
}

class _AppleMusicSearchScreenState extends State<AppleMusicSearchScreen> {
  final _ctrl = TextEditingController();
  List<AppleMusicTrack> _results = const [];
  bool _busy = false;
  bool _searched = false;
  String? _error;
  String? _previewing;
  late AppleMusicPort _am;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _am = AppScope.of(context).appleMusic;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _am.stop();
    super.dispose();
  }

  Future<void> _search() async {
    final am = AppScope.of(context).appleMusic;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await am.search(_ctrl.text);
      if (mounted) {
        setState(() {
          _results = r;
          _searched = true;
        });
      }
    } on AppleMusicException {
      if (mounted)
        setState(
          () => _error = context.tr(
            'Die Suche hat nicht geklappt. Bitte Internet und Apple-Music-Zugriff prüfen.',
            'The search failed. Please check your internet and Apple Music access.',
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(AppleMusicTrack t) async {
    final am = AppScope.of(context).appleMusic;
    if (_previewing == t.id) {
      await am.stop();
      setState(() => _previewing = null);
      return;
    }
    try {
      await am.play(t.id);
      if (mounted) setState(() => _previewing = t.id);
    } on AppleMusicException {
      if (mounted)
        setState(
          () => _error = context.tr(
            'Der Titel lässt sich nicht abspielen (Abo prüfen).',
            'This song cannot be played (check your subscription).',
          ),
        );
    }
  }

  Future<void> _choose(AppleMusicTrack t) async {
    final d = AppScope.of(context);
    await d.appleMusic.stop();
    await d.settings.update((s) => s.appleMusic = t);
    await d.settings.updateProfile(
      (p) => p.copyWith(musicId: appleMusicSoundId),
    );
    await d.timer.changeMusic();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apple Music')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: context.tr(
                  'Titel oder Künstler suchen',
                  'Search song or artist',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: context.tr('Suchen', 'Search'),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              context.tr(
                'Nicht jugendfreie Titel werden herausgefiltert. Die Musik wird von Apple Music abgespielt.',
                'Explicit songs are filtered out. Music is played by Apple Music.',
              ),
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B6485)),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFB3261E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: _searched && _results.isEmpty && !_busy
                ? Center(
                    child: Text(
                      context.tr('Nichts gefunden.', 'Nothing found.'),
                    ),
                  )
                : ListView(
                    children: [
                      for (final t in _results)
                        ListTile(
                          title: Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            t.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: IconButton(
                            tooltip: _previewing == t.id
                                ? context.tr('Anhalten', 'Stop')
                                : context.tr('Anhören', 'Listen'),
                            icon: Icon(
                              _previewing == t.id
                                  ? Icons.stop_circle_rounded
                                  : Icons.play_circle_rounded,
                              size: 34,
                              color: Brand.indigo,
                            ),
                            onPressed: () => _toggle(t),
                          ),
                          trailing: FilledButton(
                            onPressed: () => _choose(t),
                            child: Text(context.tr('Wählen', 'Select')),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
