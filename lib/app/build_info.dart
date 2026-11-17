/// Build-Kennung, beim Bauen per `--dart-define` gesetzt (siehe `tools/build_web.sh`).
/// Ohne Angabe (z. B. `flutter run`) steht dort „dev“.
const String buildSha = String.fromEnvironment('GIT_SHA', defaultValue: 'dev');
const String buildBranch = String.fromEnvironment(
  'GIT_BRANCH',
  defaultValue: 'lokal',
);
const String buildTime = String.fromEnvironment(
  'BUILD_TIME',
  defaultValue: 'unbekannt',
);

/// Kurzform für Anzeige, z. B. „db4509e · feature/premium-redesign“.
String get buildLabel =>
    '${buildSha.length > 7 ? buildSha.substring(0, 7) : buildSha} · $buildBranch';
