import 'package:flutter/material.dart';

/// Design-Tokens von TinyTakt.
class Brand {
  static const indigo = Color(0xFF3B2F7F);
  static const indigoDark = Color(0xFF241B57);
  static const coral = Color(0xFFFF7A59);
  static const sun = Color(0xFFFFC83D);
  static const mint = Color(0xFF2FC4A8);
  static const sky = Color(0xFF6EC1F5);
  static const cream = Color(0xFFFFF8EC);
  static const ink = Color(0xFF2B2440);
  static const fontFamily = 'Nunito';

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: indigo,
      brightness: Brightness.light,
      primary: indigo,
      secondary: coral,
      surface: cream,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: cream,
      textTheme: const TextTheme().apply(bodyColor: ink, displayColor: ink),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            fontFamily: fontFamily,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w900,
          fontSize: 22,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? mint : const Color(0xFFB8B2CC),
        ),
      ),
    );
  }
}

/// Zweisprachige Texte (Deutsch/Englisch) ohne Codegenerierung.
extension Tr on BuildContext {
  bool get isDe => Localizations.localeOf(this).languageCode == 'de';
  String tr(String de, String en) => isDe ? de : en;
}

String formatClock(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Sprechbare Dauer für Screenreader, z. B. „4 Minuten 30 Sekunden“.
String spokenDuration(int totalSeconds, bool de) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final parts = <String>[];
  if (h > 0)
    parts.add(
      de
          ? '$h ${h == 1 ? 'Stunde' : 'Stunden'}'
          : '$h ${h == 1 ? 'hour' : 'hours'}',
    );
  if (m > 0)
    parts.add(
      de
          ? '$m ${m == 1 ? 'Minute' : 'Minuten'}'
          : '$m ${m == 1 ? 'minute' : 'minutes'}',
    );
  if (s > 0 || parts.isEmpty)
    parts.add(
      de
          ? '$s ${s == 1 ? 'Sekunde' : 'Sekunden'}'
          : '$s ${s == 1 ? 'second' : 'seconds'}',
    );
  return parts.join(' ');
}
