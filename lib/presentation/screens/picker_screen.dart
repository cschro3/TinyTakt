import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../domain/catalog.dart';
import '../../platform/apple_music_service.dart';
import '../painters/character_painter.dart';
import '../painters/scene_painter.dart';
import '../painters/picture_painters.dart';
import '../painters/timer_painters.dart';
import '../theme.dart';
import '../widgets/preview_cache.dart';
import 'pro_screen.dart';

/// Auswahl für Kinder: Figur, Welt, Timer-Art, Musik.
/// Gesperrte (Pro-)Einträge öffnen nur die Elternsicherung – nie direkt den Kauf.
class PickerScreen extends StatefulWidget {
  const PickerScreen({super.key});

  @override
  State<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends State<PickerScreen> {
  @override
  void dispose() {
    // Beim Schließen nur die zuletzt benutzten Vorschauen behalten (schont Speicher der Timer-Szene)
    PreviewCache.instance.cancelPending();
    PreviewCache.instance.trim(14);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('Wähle aus', 'Choose')),
          bottom: TabBar(
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontFamily: Brand.fontFamily,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.pets_rounded),
                text: context.tr('Figur', 'Friend'),
              ),
              Tab(
                icon: const Icon(Icons.landscape_rounded),
                text: context.tr('Welt', 'World'),
              ),
              Tab(
                icon: const Icon(Icons.timelapse_rounded),
                text: context.tr('Zeit', 'Timer'),
              ),
              Tab(
                icon: const Icon(Icons.music_note_rounded),
                text: context.tr('Musik', 'Music'),
              ),
            ],
          ),
        ),
        // Seiten bleiben erhalten (kein Neuaufbau/Neuzeichnen beim Zurückwechseln, Scrollposition bleibt)
        body: const Stack(
          children: [
            TabBarView(
              children: [
                _KeepAlive(_Characters()),
                _KeepAlive(_Worlds()),
                _KeepAlive(_Styles()),
                _KeepAlive(_Music()),
              ],
            ),
            _WarmUp(),
          ],
        ),
      ),
    );
  }
}

/// Wärmt kurz nach dem Öffnen unsichtbar die Welt- und Zeit-Vorschauen vor (ein Bild pro Frame),
/// damit der erste Wechsel auf diese Tabs nichts mehr zeichnen muss. Danach wird der Teilbaum entfernt.
class _WarmUp extends StatefulWidget {
  const _WarmUp();
  @override
  State<_WarmUp> createState() => _WarmUpState();
}

class _WarmUpState extends State<_WarmUp> {
  bool _go = false, _done = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _go = true);
      PreviewCache.instance.pending.addListener(_check);
    });
  }

  void _check() {
    if (PreviewCache.instance.pending.value == 0 && mounted && _go && !_done) {
      // Seiten sind fertig gelayoutet; sobald die Warteschlange leer ist, Teilbaum entfernen
      Future<void>.delayed(const Duration(milliseconds: 100), () {
        if (mounted && PreviewCache.instance.pending.value == 0)
          setState(() => _done = true);
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    PreviewCache.instance.pending.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_go || _done) return const SizedBox.shrink();
    return const Positioned.fill(
      child: PreviewWarmUpScope(
        child: Offstage(
          child: Stack(
            children: [
              Positioned.fill(child: _Worlds()),
              Positioned.fill(child: _Styles()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hält eine Tab-Seite am Leben, solange das Menü offen ist.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive(this.child);
  final Widget child;
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Auswahl und Rechte ändern das Menü – der Timer-Takt nicht (früher: `d.all` inkl. Timer).
Listenable _pickerListenable(AppDeps d) =>
    Listenable.merge([d.settings, d.entitlements]);

/// Einmal vorberechnet statt je Kachel gefiltert.
final Map<CharacterCategory, List<CharacterSpec>> _charsByCategory = {
  for (final cat in CharacterCategory.values)
    cat: [
      for (final c in characters)
        if (c.category == cat) c,
    ],
};

/// Kachel-Rahmen (Schatten, weiße Karte, Rand) – wird einmal gebacken statt je Bild mit
/// Weichzeichner-Schatten und Clip gezeichnet. Maße und Farben wie zuvor.
void _paintTileChrome(Canvas c, Size s, bool selected) {
  const r = 24.0;
  final rrect = RRect.fromRectAndRadius(
    Offset.zero & s,
    const Radius.circular(r),
  );
  final shadow = BoxShadow(
    color: Brand.indigo.withValues(alpha: selected ? 0.28 : 0.08),
    blurRadius: selected ? 16 : 8,
    offset: const Offset(0, 4),
  );
  c.drawRRect(rrect.shift(shadow.offset), shadow.toPaint());
  c.drawRRect(rrect, Paint()..color = Colors.white);
  Border.all(
    color: selected ? Brand.indigo : const Color(0xFFE9E4F5),
    width: selected ? 3.5 : 1.5,
  ).paint(c, Offset.zero & s, borderRadius: BorderRadius.circular(r));
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.selected,
    required this.locked,
    required this.label,
    required this.child,
    required this.onTap,
  });
  final bool selected, locked;
  final String label;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // „Lumi (der Ruhige)“ → Name + Beiname in zwei Zeilen statt abgeschnitten
    final m = RegExp(r'^(.*?)\s*\((.*)\)\s*$').firstMatch(label);
    final name = m?.group(1) ?? label;
    final sub = m?.group(2);
    const r = 24.0;
    final bw = selected ? 3.5 : 1.5; // Randbreite belegt wie zuvor Platz
    return Semantics(
      button: true,
      selected: selected,
      label: label + (locked ? ', ${context.tr('Pro', 'Pro')}' : ''),
      excludeSemantics: true,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.985,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // gebackener Rahmen inkl. Schatten (ragt 28 px über die Kachel hinaus)
            Positioned.fill(
              child: IgnorePointer(
                child: CachedPreview(
                  cacheKey: selected ? 'chrome|sel' : 'chrome|uns',
                  margin: const Offset(28, 28),
                  paint: (c, s) => _paintTileChrome(c, s, selected),
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(r),
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      6 + bw,
                      6 + bw,
                      6 + bw,
                      8 + bw,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r - 8),
                              gradient: const RadialGradient(
                                center: Alignment(0, -0.2),
                                radius: 0.9,
                                colors: [Color(0xFFFFFFFF), Color(0xFFF1ECFF)],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: child,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            height: 1.1,
                          ),
                        ),
                        if (sub != null)
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                              height: 1.2,
                              color: Color(0xFF6B6488),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Brand.indigo,
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            if (locked)
              const Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Brand.sun,
                  child: Icon(Icons.lock_rounded, size: 16, color: Brand.ink),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

SliverGridDelegate _grid(double extent) =>
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: extent,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
    );

class _Characters extends StatelessWidget {
  const _Characters();
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return ListenableBuilder(
      listenable: _pickerListenable(d),
      builder: (context, _) {
        final sel = d.settings.profile.characterId;
        return CustomScrollView(
          slivers: [
            if (d.isPro && d.settings.customMotifs.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _Header(context.tr('Meine Bilder', 'My pictures')),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid.builder(
                  gridDelegate: _grid(130),
                  itemCount: d.settings.customMotifs.length,
                  itemBuilder: (_, i) {
                    final name = d.settings.customMotifs[i];
                    return _Tile(
                      selected: sel == 'photo:$name',
                      locked: false,
                      label: context.tr('Foto ${i + 1}', 'Photo ${i + 1}'),
                      onTap: () => d.settings.updateProfile(
                        (p) => p.copyWith(characterId: 'photo:$name'),
                      ),
                      child: FutureBuilder<File?>(
                        future: d.motifs.fileFor(name),
                        builder: (_, s) => s.data == null
                            ? const SizedBox()
                            : ClipOval(
                                child: Image.file(s.data!, fit: BoxFit.cover),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
            for (final cat in CharacterCategory.values) ...[
              SliverToBoxAdapter(
                child: _Header(context.isDe ? cat.de : cat.en),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid.builder(
                  gridDelegate: _grid(130),
                  itemCount: _charsByCategory[cat]!.length,
                  itemBuilder: (_, i) {
                    final c = _charsByCategory[cat]![i];
                    final locked = c.pro && !d.isPro;
                    return _Tile(
                      selected: sel == c.id,
                      locked: locked,
                      label: context.isDe ? c.de : c.en,
                      onTap: () => locked
                          ? openPro(context)
                          : d.settings.updateProfile(
                              (p) => p.copyWith(characterId: c.id),
                            ),
                      child: CachedPreview(
                        cacheKey: 'char:${c.id}',
                        margin: const Offset(
                          14,
                          14,
                        ), // Überhang (Funkeln, Schatten) bleibt erhalten
                        opacity: locked ? 0.6 : 1,
                        paint: (cv, sz) =>
                            CharacterPainter(c, shadow: false).paint(cv, sz),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
    ),
  );
}

class _Worlds extends StatelessWidget {
  const _Worlds();
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return ListenableBuilder(
      listenable: _pickerListenable(d),
      builder: (context, _) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: _grid(180),
        itemCount: backgrounds.length,
        itemBuilder: (_, i) {
          final b = backgrounds[i];
          final locked = b.pro && !d.isPro;
          return _Tile(
            selected: d.settings.profile.backgroundId == b.id,
            locked: locked,
            label: context.isDe ? b.de : b.en,
            onTap: () => locked
                ? openPro(context)
                : d.settings.updateProfile(
                    (p) => p.copyWith(backgroundId: b.id),
                  ),
            child: CachedPreview(
              cacheKey: 'world:${b.id}',
              opacity: locked ? 0.6 : 1,
              paint: (cv, sz) {
                // gerundete Ecken wie zuvor (ClipRRect 14), einmal mitgebacken
                cv.clipRRect(
                  RRect.fromRectAndRadius(
                    Offset.zero & sz,
                    const Radius.circular(14),
                  ),
                );
                ScenePainter(b, calm: true).paint(cv, sz);
              },
            ),
          );
        },
      ),
    );
  }
}

class _Styles extends StatelessWidget {
  const _Styles();
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return ListenableBuilder(
      listenable: _pickerListenable(d),
      builder: (context, _) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: _grid(180),
        itemCount: TimerStyle.values.length,
        itemBuilder: (_, i) {
          final s = TimerStyle.values[i];
          final locked = s.pro && !d.isPro;
          return _Tile(
            selected: d.settings.profile.style == s,
            locked: locked,
            label: context.isDe ? s.de : s.en,
            onTap: () => locked
                ? openPro(context)
                : d.settings.updateProfile((p) => p.copyWith(style: s)),
            child: CachedPreview(
              cacheKey: 'style:${s.name}',
              margin: const Offset(
                20,
                20,
              ), // Diorama/Schatten ragen über das Quadrat hinaus
              opacity: locked ? 0.6 : 1,
              paint: (cv, sz) => _StylePreview(s).paint(cv, sz),
            ),
          );
        },
      ),
    );
  }
}

class _StylePreview extends CustomPainter {
  _StylePreview(this.s);
  final TimerStyle s;
  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    final sz = Size(side, side);
    switch (s) {
      case TimerStyle.circle:
        RingPainter(
          fraction: 0.65,
          color: const Color(0xFF2FC4A8),
          ticks: false,
        ).paint(canvas, sz);
      case TimerStyle.adventure:
        canvas.drawRect(
          Offset.zero & sz,
          Paint()..color = const Color(0xFFCFEFFF),
        );
        AdventurePainter(fraction: 0.5, t: 0, calm: true).paint(canvas, sz);
      case TimerStyle.fill:
        FillPainter(
          fraction: 0.6,
          t: 0,
          color: const Color(0xFF3FB6E0),
          calm: true,
        ).paint(canvas, sz);
      case TimerStyle.rainbow:
        canvas.drawRect(
          Offset.zero & sz,
          Paint()..color = const Color(0xFFCFEFFF),
        );
        RainbowPainter(fraction: 0.6).paint(canvas, sz);
      case TimerStyle.hourglass:
        HourglassPainter(fraction: 0.55, t: 0, calm: true).paint(canvas, sz);
      case TimerStyle.iceCream:
      case TimerStyle.candle:
      case TimerStyle.plant:
      case TimerStyle.pizza:
      case TimerStyle.puzzle:
        PicturePainter(
          style: s,
          fraction: s == TimerStyle.plant ? 0.4 : 0.6,
          t: 0,
          calm: true,
        ).paint(canvas, sz);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StylePreview o) => o.s != s;
}

class _Music extends StatelessWidget {
  const _Music();
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final tracks = sounds.where((s) => s.kind == SoundKind.music).toList();
    return ListenableBuilder(
      listenable: _pickerListenable(d),
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Apple-Music-Titel, den die Eltern zuvor gewählt haben (Kinder können nicht suchen).
          if (d.appleMusic.isSupported && d.settings.appleMusic != null)
            Card(
              child: ListTile(
                minVerticalPadding: 14,
                leading: const Icon(
                  Icons.queue_music_rounded,
                  size: 30,
                  color: Brand.indigo,
                ),
                title: Text(
                  d.settings.appleMusic!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  'Apple Music · ${d.settings.appleMusic!.artist}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: d.settings.profile.musicId == appleMusicSoundId
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Brand.indigo,
                        size: 30,
                      )
                    : null,
                onTap: () async {
                  await d.settings.updateProfile(
                    (p) => p.copyWith(musicId: appleMusicSoundId),
                  );
                  await d.timer.changeMusic();
                },
              ),
            ),
          for (final s in tracks)
            Card(
              child: ListTile(
                minVerticalPadding: 14,
                leading: Icon(
                  s.asset.isEmpty
                      ? Icons.music_off_rounded
                      : Icons.music_note_rounded,
                  size: 30,
                  color: Brand.indigo,
                ),
                title: Text(
                  context.isDe ? s.de : s.en,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                subtitle: s.category == null ? null : Text(s.category!),
                trailing: d.settings.profile.musicId == s.id
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Brand.indigo,
                        size: 30,
                      )
                    : (s.pro && !d.isPro
                          ? const Icon(Icons.lock_rounded, color: Brand.coral)
                          : null),
                onTap: () async {
                  if (s.pro && !d.isPro) return openPro(context);
                  await d.settings.updateProfile(
                    (p) => p.copyWith(musicId: s.id),
                  );
                  await d.timer.changeMusic();
                },
              ),
            ),
        ],
      ),
    );
  }
}
