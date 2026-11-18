import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Legt die Messwerte als JSON-Text in `window.__ttPerf` ab (für Browser-Tests/Konsole).
void publishPerf(String json) {
  globalContext.setProperty('__ttPerf'.toJS, json.toJS);
}

/// Millisekunden seit Seitenstart (`performance.now()`).
double pageNowMs() {
  final perf = globalContext.getProperty<JSObject>('performance'.toJS);
  return perf.callMethod<JSNumber>('now'.toJS).toDartDouble;
}

/// `?perf=1` in der Adresse.
bool perfRequestedByUrl() => Uri.base.queryParameters['perf'] == '1';

/// `?tier=full|reduced|minimal` in der Adresse: Qualitätsstufe fest wählen (Messungen).
String? perfTierByUrl() => Uri.base.queryParameters['tier'];
