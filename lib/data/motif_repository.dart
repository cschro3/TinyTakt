import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Eigene Fotos als Timer-Motiv (Pro). Ausschließlich lokal.
///
/// `image_picker` nutzt den System-Photo-Picker (PHPicker auf iOS, Android
/// Photo Picker ab Android 13 bzw. Storage Access Framework), daher sind keine
/// Foto-Berechtigungen erforderlich. Das Bild wird in den privaten
/// App-Ordner kopiert, auf max. 1024 px verkleinert und kann gelöscht werden.
class MotifRepository {
  MotifRepository({ImagePicker? picker, Future<Directory> Function()? dir})
    : _picker = picker ?? ImagePicker(),
      _dir = dir ?? getApplicationDocumentsDirectory;
  final ImagePicker _picker;
  final Future<Directory> Function() _dir;

  Future<Directory> _motifDir() async {
    final d = Directory(p.join((await _dir()).path, 'motifs'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Gibt den Dateinamen (nicht den Pfad) zurück oder null bei Abbruch.
  Future<String?> pickAndStore() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (x == null) return null;
    final dir = await _motifDir();
    final name = 'm${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(x.path).copy(p.join(dir.path, name));
    return name;
  }

  Future<File?> fileFor(String name) async {
    if (name.contains('/') || name.contains('..')) return null;
    final f = File(p.join((await _motifDir()).path, name));
    return await f.exists() ? f : null;
  }

  Future<void> delete(String name) async {
    final f = await fileFor(name);
    if (f != null) await f.delete();
  }
}
