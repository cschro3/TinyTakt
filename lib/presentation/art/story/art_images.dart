import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lädt und hält die gerasterten Illustrationen (WebP) für die „Story“-Darstellung.
///
/// **Prototyp-Assets** (siehe `docs/art/PROTOTYP_ASSETS.md`): Mira ist mit echtem Alpha
/// aus dem Konzeptbild freigestellt, die Wiese ist das zusammengesetzte Referenzbild.
/// Solange die Bilder nicht geladen sind, bleibt die bisherige Darstellung aktiv.
class ArtImages extends ChangeNotifier {
  ArtImages._();
  static final ArtImages instance = ArtImages._();

  static const miraAsset = 'assets/art/mira/mira_prototype.webp';
  static const meadowAsset = 'assets/art/meadow/meadow_prototype.webp';

  ui.Image? mira;
  ui.Image? meadow;
  Future<void>? _loading;

  bool get ready => mira != null && meadow != null;

  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final m = await _decode(miraAsset);
      final w = await _decode(meadowAsset);
      mira = m;
      meadow = w;
      notifyListeners();
    } catch (e) {
      debugPrint('Story-Bilder nicht ladbar, Fallback aktiv: $e');
      _loading = null; // nächster Versuch möglich
    }
  }

  Future<ui.Image> _decode(String key) async {
    final data = await rootBundle.load(key);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Nur für Tests: Bilder direkt setzen.
  @visibleForTesting
  void setForTest({ui.Image? mira, ui.Image? meadow}) {
    this.mira = mira;
    this.meadow = meadow;
    notifyListeners();
  }
}
