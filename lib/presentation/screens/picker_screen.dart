import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../domain/catalog.dart';
import '../painters/character_painter.dart';
import '../painters/scene_painter.dart';
import '../painters/timer_painters.dart';
import '../theme.dart';
import 'pro_screen.dart';

/// Auswahl für Kinder: Figur, Welt, Timer-Art, Musik.
/// Gesperrte (Pro-)Einträge öffnen nur die Elternsicherung – nie direkt den Kauf.
class PickerScreen extends StatelessWidget {
  const PickerScreen({super.key});

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
        body: const TabBarView(
          children: [_Characters(), _Worlds(), _Styles(), _Music()],
        ),
      ),
    );
  }
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
    return Semantics(
      button: true,
      selected: selected,
      label: label + (locked ? ', ${context.tr('Pro', 'Pro')}' : ''),
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: selected ? Brand.indigo : const Color(0xFFE3DEF1),
                      width: selected ? 4 : 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: locked ? 0.55 : 1,
                          child: child,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  top: 6,
                  right: 6,
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
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 13,
                    backgroundColor: Brand.sun,
                    child: Icon(Icons.lock_rounded, size: 16, color: Brand.ink),
                  ),
                ),
            ],
          ),
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
      childAspectRatio: 0.92,
    );

class _Characters extends StatelessWidget {
  const _Characters();
  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    return ListenableBuilder(
      listenable: d.all,
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
                  itemCount: characters.where((c) => c.category == cat).length,
                  itemBuilder: (_, i) {
                    final c = characters
                        .where((c) => c.category == cat)
                        .toList()[i];
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
                      child: CharacterView(spec: c),
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
      listenable: d.all,
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: ScenePainter(b, calm: true),
                size: Size.infinite,
              ),
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
      listenable: d.all,
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
            child: CustomPaint(painter: _StylePreview(s), size: Size.infinite),
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
      listenable: d.all,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(12),
        children: [
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
