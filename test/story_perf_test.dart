import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:tinytakt/data/settings_repository.dart';
import 'package:tinytakt/data/stores.dart';
import 'package:tinytakt/domain/clock.dart';
import 'package:tinytakt/domain/timer_engine.dart';
import 'package:tinytakt/platform/audio_service.dart';
import 'package:tinytakt/platform/notification_service.dart';
import 'package:tinytakt/app/timer_controller.dart';
import 'package:tinytakt/presentation/art/figures/registry.dart';
import 'package:tinytakt/presentation/art/rig.dart';
import 'package:tinytakt/presentation/art/story/art_images.dart';
import 'package:tinytakt/presentation/art/story/meadow_path.dart';
import 'package:tinytakt/presentation/art/story/meadow_story.dart';
import 'package:tinytakt/presentation/art/story/mira_cells.dart';
import 'package:tinytakt/presentation/art/story/mira_sprite.dart';
import 'package:tinytakt/presentation/art/story/story_quality.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mira-Netz: schnelle Verformung', () {
    testWidgets('weicht höchstens minimal von der exakten Formel ab', (
      t,
    ) async {
      await t.runAsync(ArtImages.instance.ensureLoaded);
      final data = ArtImages.instance.miraMesh!;
      final p = premiumFigures['nova_mira']!.personality;
      const feet = Offset(100, 300);
      const height = 200.0;
      final width = height * data.image.width / data.image.height;
      var worst = 0.0;
      for (final e in Emotion.values) {
        for (var i = 0; i < 25; i++) {
          final tt = i * 0.37;
          final pose = computePose(p, e, tt, i * 0.21);
          final fast = Float32List.fromList(
            MiraFastMesh.fill(data, feet, height, pose, tt, lean: 0.02),
          );
          for (var j = 0; j <= MiraMeshData.rows; j += 4) {
            for (var c = 0; c <= MiraMeshData.cols; c += 4) {
              final k = j * (MiraMeshData.cols + 1) + c;
              final q = MiraMesh.deform(
                Offset(c / MiraMeshData.cols, j / MiraMeshData.rows),
                pose,
                tt,
              );
              final x = (q.dx - 0.5) * width * (1 + pose.squash * 0.10);
              final y =
                  (q.dy - MiraMesh.feetV) * height * (1 - pose.squash * 0.12);
              final a = 0.02 + pose.lean;
              final ex = feet.dx + x * math.cos(a) - y * math.sin(a);
              final ey =
                  feet.dy +
                  x * math.sin(a) +
                  y * math.cos(a) +
                  pose.bodyDy * 0.5 * height;
              final d = math.sqrt(
                math.pow(fast[k * 2] - ex, 2) +
                    math.pow(fast[k * 2 + 1] - ey, 2),
              );
              worst = math.max(worst, d / height);
            }
          }
        }
      }
      // Kleinwinkel-Näherung und Atem-Maske: < 0,6 % der Figurhöhe (≈ 1 px bei 180 px Höhe)
      expect(worst, lessThan(0.006));
    });

    testWidgets(
      'vorberechnete Zellmaske passt zum Mira-Bild (tools/mira_cells.py)',
      (t) async {
        await t.runAsync(() async {
          final bytes = await _load(ArtImages.miraAsset);
          final img = (await (await ui.instantiateImageCodec(
            bytes,
          )).getNextFrame()).image;
          final px = (await img.toByteData())!;
          final w = img.width, h = img.height;
          const n = MiraMeshData.cols;
          final buf = StringBuffer();
          for (var cy = 0; cy < n; cy++) {
            for (var cx = 0; cx < n; cx++) {
              final x0 = cx * w ~/ n, x1 = (cx + 1) * w ~/ n;
              final y0 = cy * h ~/ n, y1 = (cy + 1) * h ~/ n;
              var any = false;
              for (
                var y = math.max(y0 - 1, 0);
                y < math.min(y1 + 1, h) && !any;
                y++
              ) {
                for (
                  var x = math.max(x0 - 1, 0);
                  x < math.min(x1 + 1, w);
                  x++
                ) {
                  if (px.getUint8((y * w + x) * 4 + 3) > 0) {
                    any = true;
                    break;
                  }
                }
              }
              buf.write(any ? '1' : '0');
            }
          }
          expect(
            miraActiveCells,
            buf.toString(),
            reason: 'python3 tools/mira_cells.py ausführen',
          );
        });
      },
    );

    testWidgets('Netz überspringt transparente Zellen, Indizes sind gültig', (
      t,
    ) async {
      await t.runAsync(ArtImages.instance.ensureLoaded);
      final d = ArtImages.instance.miraMesh!;
      expect(d.indices.length % 3, 0);
      for (final i in d.indices) {
        expect(i, lessThan(MiraMeshData.vertexCount));
      }
      expect(
        d.activeShare,
        inInclusiveRange(0.3, 0.9),
      ); // spart Dreiecke und Füllfläche
      expect(d.tex.length, MiraMeshData.vertexCount * 2);
    });
  });

  group('Bildgrößen und Texturspeicher', () {
    testWidgets('iPhone 393 pt @3: kleines Mira-Bild, Wiese in voller Breite', (
      t,
    ) async {
      final a = ArtImages.instance..resetForTest();
      await t.runAsync(() => a.ensureLoaded(cssWidth: 393, dpr: 3));
      expect(a.loadedMiraAsset, ArtImages.mira512Asset);
      expect(
        a.loadedMeadowAsset,
        ArtImages.meadowAsset,
      ); // 1179 px ≈ Quellbreite
      expect(a.mira!.height, 512);
      expect(a.textureMB, lessThan(8));
      a.resetForTest();
    });

    testWidgets('kleines Gerät 360 pt @2: beide Bilder verkleinert', (t) async {
      final a = ArtImages.instance..resetForTest();
      await t.runAsync(() => a.ensureLoaded(cssWidth: 360, dpr: 2));
      expect(a.loadedMiraAsset, ArtImages.mira512Asset);
      expect(a.loadedMeadowAsset, ArtImages.meadow900Asset);
      expect(a.textureMB, lessThan(5));
      expect(a.meadowScale, closeTo(900 / 1199, 1e-6));
      a.resetForTest();
    });

    testWidgets('iPad 1032 pt @2: volle Auflösung (nicht unscharf)', (t) async {
      final a = ArtImages.instance..resetForTest();
      await t.runAsync(() => a.ensureLoaded(cssWidth: 1032, dpr: 2));
      expect(a.loadedMiraAsset, ArtImages.miraAsset);
      expect(a.loadedMeadowAsset, ArtImages.meadowAsset);
      a.resetForTest();
    });

    testWidgets('verkleinertes Mira-Bild hat echtes Alpha und gleiche Form', (
      t,
    ) async {
      await t.runAsync(() async {
        final bytes = await _load(ArtImages.mira512Asset);
        final codec = await ui.instantiateImageCodec(bytes);
        final img = (await codec.getNextFrame()).image;
        final px = (await img.toByteData())!;
        expect(px.getUint8(3), 0); // Ecke oben links
        expect(px.getUint8((img.width * img.height - 1) * 4 + 3), 0);
        expect(img.width / img.height, closeTo(1097 / 1093, 0.01));
      });
    });
  });

  group('Qualitätsregler', () {
    test('Raten sinken mit der Stufe, Effekte werden weniger', () {
      for (final active in [true, false]) {
        final r = [
          for (final t in StoryTier.values)
            StoryGovernor.sceneHz(t, active: active),
        ];
        expect(r[0], greaterThan(r[1]));
        expect(r[1], greaterThan(r[2]));
      }
      expect(StoryGovernor.sceneHz(StoryTier.full, active: true), 60);
      expect(
        StoryGovernor.particles(StoryTier.full),
        greaterThan(StoryGovernor.particles(StoryTier.reduced)),
      );
      expect(StoryGovernor.particles(StoryTier.minimal), 0);
      expect(StoryGovernor.wind(StoryTier.minimal), isFalse);
      expect(StoryGovernor.ambientHz(StoryTier.minimal), 0);
    });

    test('schaltet nur bei dauerhaft zu niedriger Bildrate herunter', () {
      var fps = 60.0;
      final g = StoryGovernor(fpsProbe: () => fps);
      var t = 0.0;
      bool tick() => g.evaluate(t += 1.01, 60, visible: true);
      for (var i = 0; i < 6; i++) {
        expect(tick(), isFalse); // 60 fps: bleibt
      }
      fps = 20; // dauerhaft schlecht
      var changes = 0;
      for (var i = 0; i < 4; i++) {
        if (tick()) changes++;
      }
      expect(g.tier, StoryTier.reduced);
      expect(changes, 1);
      for (var i = 0; i < 12; i++) {
        tick();
      }
      expect(g.tier, StoryTier.minimal);
      for (var i = 0; i < 12; i++) {
        tick();
      }
      expect(g.tier, StoryTier.minimal); // tiefer geht nicht
    });

    test(
      'ignoriert Einbrüche ohne Frames (Tab im Hintergrund) und Unsichtbarkeit',
      () {
        var fps = 0.0;
        final g = StoryGovernor(fpsProbe: () => fps);
        var t = 0.0;
        for (var i = 0; i < 20; i++) {
          g.evaluate(t += 1.01, 60, visible: true);
        }
        expect(g.tier, StoryTier.full);
        fps = 10;
        for (var i = 0; i < 20; i++) {
          g.evaluate(t += 1.01, 60, visible: false);
        }
        expect(g.tier, StoryTier.full);
      },
    );

    test('Stromsparmodus erzwingt die niedrigste Stufe', () {
      final g = StoryGovernor(fpsProbe: () => 60)..forceMinimal = true;
      expect(g.effective, StoryTier.minimal);
    });

    test('kehrt höchstens zweimal nach stabiler Leistung zurück', () {
      var fps = 15.0;
      final g = StoryGovernor(fpsProbe: () => fps);
      var t = 0.0;
      for (var i = 0; i < 12; i++) {
        g.evaluate(t += 1.01, 60, visible: true);
      }
      expect(g.tier, StoryTier.minimal);
      fps = 60;
      for (var i = 0; i < 80; i++) {
        g.evaluate(t += 1.01, 60, visible: true);
      }
      expect(g.tier, StoryTier.full); // zwei Stufen zurück
      fps = 15;
      for (var i = 0; i < 12; i++) {
        g.evaluate(t += 1.01, 60, visible: true);
      }
      expect(g.tier, StoryTier.minimal);
      fps = 60;
      for (var i = 0; i < 80; i++) {
        g.evaluate(t += 1.01, 60, visible: true);
      }
      expect(g.tier, StoryTier.minimal); // Rückkehr-Kontingent erschöpft
    });
  });

  group('Wiesen-Netz und Geometrie', () {
    testWidgets('Wind bewegt nur den Vordergrund; Ruhelage ist exakt', (
      t,
    ) async {
      await t.runAsync(ArtImages.instance.ensureLoaded);
      final img = ArtImages.instance.meadow!;
      const size = Size(393, 852);
      final geo = StoryGeometry(size, pathBottomY: 440);
      final m = BackdropMesh(
        geo: geo,
        screen: size,
        src: img,
        texScale: 1,
        yStart: 700,
        yEnd: MeadowPath.imageSize.height,
        rows: 14,
        cols: 18,
        topFadeFromY: 700,
        topFadePx: 24,
      );
      final rest = m.pos;
      // Ruhelage
      m.draw(ui.PictureRecorder().let((r) => Canvas(r)), 1.0, 0);
      final restX = Float32List.fromList([
        for (var k = 0; k < rest.length; k += 2) rest[k],
      ]);
      m.draw(ui.PictureRecorder().let((r) => Canvas(r)), 1.0, 3);
      var moved = 0;
      for (var k = 0; k < restX.length; k++) {
        if ((rest[k * 2] - restX[k]).abs() > 1e-3) moved++;
      }
      expect(moved, greaterThan(restX.length ~/ 2));
      // oberste Reihe (Gewicht 0) bleibt stehen
      for (var i = 0; i <= 18; i++) {
        expect((rest[i * 2] - restX[i]).abs(), lessThan(1e-3));
      }
      // Oberkante blendet ein (Alpha 0), Vertex-Anzahl passt
      expect((m.colors.first >> 24) & 0xFF, 0);
      expect(m.indices.length, 18 * 14 * 6);
    });

    test('Geometrie: gleiche Eingaben = gleich (kein Neuaufbau nötig), andere = verschieden', () {
      const s = Size(393, 852);
      expect(
        StoryGeometry(s, pathBottomY: 440),
        StoryGeometry(s, pathBottomY: 440.2),
      );
      expect(
        StoryGeometry(s, pathBottomY: 440) ==
            StoryGeometry(s, pathBottomY: 470),
        isFalse,
      );
      expect(
        StoryGeometry(s, pathBottomY: 440) ==
            StoryGeometry(const Size(360, 640), pathBottomY: 440),
        isFalse,
      );
    });
  });

  group('Timer-Meldungen und Einstellung', () {
    test('250-ms-Takt meldet nur Sekundenwechsel, Statuswechsel immer; Zeit bleibt exakt', () {
      fakeAsync((fa) {
        final store = MemoryStore();
        final settings = SettingsRepository(store);
        final clock = FakeClock();
        final c = buildTestController(
          settings: settings,
          store: store,
          clock: clock,
          audio: SilentAudioService(),
          notifications: NoopNotificationService(),
          pro: false,
        );
        c.init();
        fa.flushMicrotasks();
        c.setDuration(const Duration(seconds: 10));
        fa.flushMicrotasks();
        c.start();
        fa.flushMicrotasks();
        var n = 0;
        c.addListener(() => n++);
        for (var i = 0; i < 20; i++) {
          clock.advance(const Duration(milliseconds: 250));
          fa.elapse(const Duration(milliseconds: 250));
        }
        // 5 simulierte Sekunden: früher 20 Meldungen, jetzt je Sekundenwechsel
        expect(n, inInclusiveRange(4, 7));
        expect(c.displaySeconds, 5);
        expect(c.engine.fractionRemaining, closeTo(0.5, 0.001));
        clock.advance(const Duration(seconds: 6));
        fa.elapse(const Duration(milliseconds: 250));
        fa.flushMicrotasks();
        expect(c.status, TimerStatus.finished);
        c.dispose();
      });
    });

    test('Struktur-Meldung: nur bei Status/Dauer/Phase, nicht bei Sekundenwechseln', () {
      fakeAsync((fa) {
        final store = MemoryStore();
        final clock = FakeClock();
        final c = buildTestController(
          settings: SettingsRepository(store),
          store: store,
          clock: clock,
          audio: SilentAudioService(),
          notifications: NoopNotificationService(),
          pro: false,
        );
        c.init();
        fa.flushMicrotasks();
        var structural = 0, ticks = 0;
        c.structure.addListener(() => structural++);
        c.addListener(() => ticks++);
        c.setDuration(const Duration(seconds: 20));
        fa.flushMicrotasks();
        expect(structural, 1, reason: 'neue Dauer ist strukturell');
        c.start();
        fa.flushMicrotasks();
        expect(structural, 2, reason: 'Start: Status wechselt');
        final afterStart = (structural, ticks);
        for (var i = 0; i < 24; i++) {
          clock.advance(const Duration(milliseconds: 250));
          fa.elapse(const Duration(milliseconds: 250));
        }
        expect(
          structural,
          afterStart.$1,
          reason: '6 s Laufzeit: keine strukturelle Meldung',
        );
        expect(
          ticks - afterStart.$2,
          inInclusiveRange(5, 8),
          reason: 'Zeitanzeige hört weiter jede Sekunde',
        );
        c.pause();
        fa.flushMicrotasks();
        expect(structural, afterStart.$1 + 1, reason: 'Pause: Status wechselt');
        c.resume();
        fa.flushMicrotasks();
        clock.advance(const Duration(seconds: 30));
        fa.elapse(const Duration(milliseconds: 250));
        fa.flushMicrotasks();
        expect(c.status, TimerStatus.finished);
        expect(
          structural,
          greaterThanOrEqualTo(afterStart.$1 + 3),
          reason: 'Ende ist strukturell',
        );
        c.dispose();
      });
    });

    test('Stromsparmodus: Standard aus, bleibt gespeichert, alte Daten ohne Feld laden', () async {
      final store = MemoryStore();
      await store.setString(
        'settings.v1',
        '{"calmMode": true, "musicVolume": 0.3}',
      );
      var s = SettingsRepository(store);
      expect(s.powerSave, isFalse);
      expect(s.calmMode, isTrue);
      expect(s.musicVolume, 0.3);
      await s.update((x) => x.powerSave = true);
      s = SettingsRepository(store);
      expect(s.powerSave, isTrue);
      expect(s.calmMode, isTrue);
    });
  });
}

Future<Uint8List> _load(String key) async {
  final data = await rootBundle.load(key);
  return data.buffer.asUint8List();
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
