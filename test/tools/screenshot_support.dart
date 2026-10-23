import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lädt echte Schriften, damit gerenderte Bilder lesbar sind (Tests nutzen sonst „Ahem“).
Future<void> loadFonts() async {
  final nunito = FontLoader('Nunito');
  for (final w in [400, 700, 800, 900]) {
    nunito.addFont(
      Future.value(
        ByteData.sublistView(
          File('assets/fonts/Nunito-$w.ttf').readAsBytesSync(),
        ),
      ),
    );
  }
  await nunito.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File(
            '/opt/sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

Future<void> savePng(
  WidgetTester t,
  GlobalKey key,
  String path, {
  double pixelRatio = 1.0,
}) async {
  await t.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = (await img.toByteData(format: ui.ImageByteFormat.png))!;
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes.buffer.asUint8List());
  });
}
