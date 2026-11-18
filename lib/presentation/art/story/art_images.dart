import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../app/perf_monitor.dart';
import 'meadow_path.dart';
import 'mira_cells.dart';
import 'mira_sprite.dart';

/// Lädt und hält die gerasterten Illustrationen (WebP) für die „Story“-Darstellung.
///
/// **Prototyp-Assets** (siehe `docs/art/PROTOTYP_ASSETS.md`): Mira ist mit echtem Alpha
/// aus dem Konzeptbild freigestellt, die Wiese ist das zusammengesetzte Referenzbild.
/// Solange die Bilder nicht geladen sind, bleibt die bisherige Darstellung aktiv.
///
/// Speicher: Es wird die kleinste Asset-Stufe geladen, die auf dem Bildschirm noch 1:1 scharf ist
/// (Mira 512 px hoch statt 1093 px, Wiese 900 px statt 1199 px breit auf kleineren Displays).
class ArtImages extends ChangeNotifier {
  ArtImages._();
  static final ArtImages instance = ArtImages._();

  /// Volle Auflösung (auch für Werkzeuge/Tests).
  static const miraAsset = 'assets/art/mira/mira_prototype.webp';
  static const meadowAsset = 'assets/art/meadow/meadow_prototype.webp';

  /// Verkleinerte Stufen für Telefone.
  static const mira512Asset = 'assets/art/mira/mira_512.webp';
  static const meadow900Asset = 'assets/art/meadow/meadow_900.webp';

  ui.Image? mira;
  ui.Image? meadow;
  MiraMeshData? miraMesh;
  String? loadedMiraAsset, loadedMeadowAsset;
  int loadMs = 0;
  Future<void>? _loading;

  /// Laden ist fehlgeschlagen: die bisherige Darstellung bleibt dauerhaft aktiv.
  bool failed = false;

  bool get ready => mira != null && meadow != null;

  /// Faktor Bildpunkte der geladenen Wiese je Bildpunkt des Referenzbilds (1199 px breit).
  double get meadowScale =>
      meadow == null ? 1 : meadow!.width / MeadowPath.imageSize.width;

  /// Geschätzter GPU-Texturspeicher der geladenen Bilder in MB (RGBA, ohne Mip-Ketten).
  double get textureMB =>
      ((mira?.width ?? 0) * (mira?.height ?? 0) +
          (meadow?.width ?? 0) * (meadow?.height ?? 0)) *
      4 /
      1048576;

  /// [cssWidth] und [dpr] bestimmen die Asset-Stufe; ohne Angabe wird die volle Auflösung geladen.
  Future<void> ensureLoaded({double? cssWidth, double? dpr}) =>
      _loading ??= _load(cssWidth, dpr);

  Future<void> _load(double? cssWidth, double? dpr) async {
    final sw = Stopwatch()..start();
    try {
      var miraKey = miraAsset, meadowKey = meadowAsset;
      if (cssWidth != null && dpr != null) {
        final s = cssWidth / MeadowPath.imageSize.width;
        final miraNeeded =
            370 * s * dpr * 1.15; // größte angezeigte Höhe in Geräte-Pixeln
        if (miraNeeded <= 512) miraKey = mira512Asset;
        if (cssWidth * dpr <= 900) meadowKey = meadow900Asset;
      }
      // beide Bilder parallel laden und decodieren
      final res = await Future.wait([_decode(miraKey), _decode(meadowKey)]);
      final m = res[0], w = res[1];
      miraMesh = MiraMeshData(m, cells: miraActiveCells);
      loadedMiraAsset = miraKey;
      loadedMeadowAsset = meadowKey;
      mira = m;
      meadow = w;
      loadMs = sw.elapsedMilliseconds;
      PerfMonitor.instance.mark('imagesLoaded');
      notifyListeners();
    } catch (e) {
      debugPrint('Story-Bilder nicht ladbar, Fallback aktiv: $e');
      failed = true;
      notifyListeners();
    }
  }

  Future<ui.Image> _decode(String key) async {
    final data = await rootBundle.load(key);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Nur für Tests: Lader zurücksetzen (neue Asset-Stufen wählbar).
  @visibleForTesting
  void resetForTest() {
    mira = null;
    meadow = null;
    miraMesh = null;
    loadedMiraAsset = loadedMeadowAsset = null;
    failed = false;
    _loading = null;
  }

  /// Nur für Tests: Bilder direkt setzen.
  @visibleForTesting
  void setForTest({ui.Image? mira, ui.Image? meadow}) {
    this.mira = mira;
    this.meadow = meadow;
    miraMesh = mira == null ? null : MiraMeshData(mira);
    notifyListeners();
  }
}
