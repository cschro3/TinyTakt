import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../domain/catalog.dart';
import '../../domain/character_profiles.dart';
import '../art/adventure/adventure_gear.dart';
import '../art/visual/character_visual_painter.dart';
import '../art/visual/figure_frames.dart';
import '../art/visual/visual_registry.dart';
import '../painters/character_painter.dart' show Mood;
import '../screens/pro_screen.dart';
import '../theme.dart';

/// Charakterkarte: großes animiertes Porträt, Steckbrief (Gruppe, Persönlichkeit, Fähigkeit,
/// Geschichte), Vorschau der Abenteuer-Ausrüstung je Welt, Favorit und Auswahl.
Future<void> showCharacterSheet(BuildContext context, CharacterSpec spec) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CharacterSheet(spec: spec),
    );

class CharacterSheet extends StatefulWidget {
  const CharacterSheet({super.key, required this.spec});
  final CharacterSpec spec;

  @override
  State<CharacterSheet> createState() => _CharacterSheetState();
}

class _CharacterSheetState extends State<CharacterSheet> {
  String? _gear; // Welt-ID der Ausrüstungsvorschau, null = ohne
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_init) {
      _init = true;
      final w = AppScope.of(context).settings.profile.backgroundId;
      _gear = adventureGear.containsKey(w) ? w : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final c = widget.spec;
    final p = profileOf(c.id);
    final de = context.isDe;
    final locked = c.pro && !d.isPro;
    final fits = gearFits(c);
    final world = backgrounds.firstWhere(
      (b) => b.id == (_gear ?? d.settings.profile.backgroundId),
      orElse: () => backgrounds.first,
    );
    final accent = VisualRegistry.accent(world.id);
    final full = de ? c.de : c.en;
    final nm = RegExp(r'^(.*?)\s*\((.*)\)\s*$').firstMatch(full);
    final title = nm?.group(1) ?? full;
    final nick = nm?.group(2);
    return ListenableBuilder(
      listenable: d.settings,
      builder: (context, _) {
        final fav = d.settings.isFavorite(c.id);
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scroll) => Container(
            decoration: const BoxDecoration(
              color: Brand.cream,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        height: 270,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.alphaBlend(
                                accent.withValues(alpha: 0.25),
                                c.c2,
                              ),
                              Color.alphaBlend(
                                accent.withValues(alpha: 0.10),
                                Colors.white,
                              ),
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: AnimatedPortrait(
                                  spec: c,
                                  gearWorld: fits ? _gear : null,
                                  size: 240,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: IconButton.filledTonal(
                                tooltip: context.tr('Schließen', 'Close'),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton.filledTonal(
                                tooltip: fav
                                    ? context.tr(
                                        'Aus Favoriten entfernen',
                                        'Remove from favourites',
                                      )
                                    : context.tr(
                                        'Zu Favoriten',
                                        'Add to favourites',
                                      ),
                                onPressed: () =>
                                    d.settings.toggleFavorite(c.id),
                                icon: Icon(
                                  fav
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: fav ? const Color(0xFFFFB300) : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nick != null)
                              Text(
                                nick,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF6B6485),
                                ),
                              ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Brand.ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (p != null)
                                  _Chip(
                                    de ? p.group.de : p.group.en,
                                    Brand.indigo,
                                  ),
                                _Chip(
                                  de ? c.category.de : c.category.en,
                                  Brand.mint,
                                ),
                                if (c.pro)
                                  _Chip('Pro', const Color(0xFFB8860B)),
                              ],
                            ),
                            if (p != null) ...[
                              const SizedBox(height: 14),
                              _Fact(
                                Icons.favorite_rounded,
                                context.tr('Persönlichkeit', 'Personality'),
                                de ? p.traitDe : p.traitEn,
                              ),
                              _Fact(
                                Icons.bolt_rounded,
                                context.tr('Fähigkeit', 'Ability'),
                                de ? p.abilityDe : p.abilityEn,
                              ),
                              _Fact(
                                Icons.menu_book_rounded,
                                context.tr('Geschichte', 'Story'),
                                de ? p.storyDe : p.storyEn,
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              context.tr(
                                'Abenteuer-Ausrüstung',
                                'Adventure gear',
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Brand.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!fits)
                              Text(
                                context.tr(
                                  'Diese Figur hat keinen Kopf für Ausrüstung – sie reist, wie sie ist.',
                                  'This character has no head for gear – it travels as it is.',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF6B6485),
                                ),
                              )
                            else
                              SizedBox(
                                height: 46,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    _GearChoice(
                                      label: context.tr('Ohne', 'None'),
                                      selected: _gear == null,
                                      onTap: () => setState(() => _gear = null),
                                    ),
                                    for (final g in adventureGear.values)
                                      _GearChoice(
                                        label: de ? g.nameDe : g.nameEn,
                                        selected: _gear == g.id,
                                        onTap: () =>
                                            setState(() => _gear = g.id),
                                      ),
                                  ],
                                ),
                              ),
                            if (fits && _gear != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  de
                                      ? adventureGear[_gear]!.itemsDe
                                      : adventureGear[_gear]!.itemsEn,
                                  style: const TextStyle(
                                    color: Color(0xFF6B6485),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.coral,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (locked) {
                            openPro(context);
                          } else {
                            d.settings.updateProfile(
                              (pr) => pr.copyWith(characterId: c.id),
                            );
                          }
                        },
                        icon: Icon(
                          locked ? Icons.lock_rounded : Icons.check_rounded,
                        ),
                        label: Text(
                          locked
                              ? context.tr(
                                  'Mit Pro freischalten',
                                  'Unlock with Pro',
                                )
                              : context.tr(
                                  'Diese Figur wählen',
                                  'Choose this character',
                                ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        color: color.withValues(alpha: 1),
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.title, this.text);
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Brand.coral),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(
              fontSize: 16,
              height: 1.25,
              color: Brand.ink,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GearChoice extends StatelessWidget {
  const _GearChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? Brand.indigo : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? Brand.indigo : const Color(0xFFE0DAF0),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : Brand.ink,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Animiertes Porträt (Atmen/Wippen). Tippen = Freude. Vektor-Figuren laufen über gebackene Frames,
/// Bild-Figuren live – wie in der Abenteuerszene. Ruhiger Modus/„Bewegung reduzieren“ = Standbild.
class AnimatedPortrait extends StatefulWidget {
  const AnimatedPortrait({
    super.key,
    required this.spec,
    required this.size,
    this.gearWorld,
  });
  final CharacterSpec spec;
  final double size;
  final String? gearWorld;

  @override
  State<AnimatedPortrait> createState() => _AnimatedPortraitState();
}

class _AnimatedPortraitState extends State<AnimatedPortrait> {
  Timer? _timer;
  final Stopwatch _sw = Stopwatch()..start();
  final ValueNotifier<double> _t = ValueNotifier(0);
  double _happyUntil = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calm =
        MediaQuery.of(context).disableAnimations ||
        AppScope.of(context).settings.calmMode;
    _timer?.cancel();
    if (!calm) {
      _timer = Timer.periodic(const Duration(milliseconds: 66), (_) {
        _t.value = _sw.elapsedMicroseconds / 1e6;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calm =
        MediaQuery.of(context).disableAnimations ||
        AppScope.of(context).settings.calmMode;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      label: context.tr(
        'Figur ${widget.spec.de} – tippen für Freude',
        'Character ${widget.spec.en} – tap to cheer',
      ),
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _happyUntil = _sw.elapsedMicroseconds / 1e6 + 1.6,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _PortraitPainter(
                this,
                widget.spec,
                widget.gearWorld,
                calm,
                dpr,
                _t,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(
    this.s,
    this.spec,
    this.gear,
    this.calm,
    this.dpr,
    Listenable repaint,
  ) : super(repaint: repaint);
  final _AnimatedPortraitState s;
  final CharacterSpec spec;
  final String? gear;
  final bool calm;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final t = s._t.value;
    final mood = !calm && t < s._happyUntil ? Mood.happy : Mood.idle;
    final bitmap =
        VisualRegistry.character(spec.id).renderer == FigureRenderer.bitmapMesh;
    if (bitmap) {
      CharacterVisualPainter(
        spec,
        t: t,
        mood: mood,
        calm: calm,
        gearWorld: gear,
      ).paint(canvas, size);
      return;
    }
    final ok = FigureFrames.instance.paint(
      canvas,
      spec,
      Offset.zero & size,
      t: t,
      mood: mood,
      calm: calm,
      dpr: dpr,
      gearWorld: gear,
    );
    if (!ok)
      CharacterVisualPainter(
        spec,
        t: t,
        mood: mood,
        calm: calm,
        gearWorld: gear,
      ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_PortraitPainter old) =>
      old.gear != gear || old.spec != spec || old.calm != calm;
}
