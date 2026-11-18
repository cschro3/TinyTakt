/// Nicht-Web: kein Export nötig.
void publishPerf(String json) {}

/// Millisekunden seit Seitenstart (Web) bzw. -1.
double pageNowMs() => -1;

/// `?perf=1` in der Adresse (nur Web).
bool perfRequestedByUrl() => false;

/// `?tier=full|reduced|minimal` in der Adresse (nur Web): Qualitätsstufe fest wählen (Messungen).
String? perfTierByUrl() => null;
