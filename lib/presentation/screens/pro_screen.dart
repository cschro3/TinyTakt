import 'package:flutter/material.dart';

import '../../app/deps.dart';
import '../../domain/catalog.dart';
import '../../platform/purchase_service.dart';
import '../theme.dart';
import '../widgets/gate_dialog.dart';

/// Öffnet den Pro-Bildschirm – ausschließlich hinter der Elternsicherung.
Future<void> openPro(BuildContext context) async {
  if (!await requireParent(
    context,
    reason: context.tr(
      'Für den Kauf ist die Erlaubnis eines Erwachsenen nötig.',
      'A grown-up needs to approve this.',
    ),
  ))
    return;
  if (!context.mounted) return;
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ProScreen()));
}

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deps = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('TinyTakt Pro')),
      body: ListenableBuilder(
        listenable: Listenable.merge([deps.purchases, deps.entitlements]),
        builder: (context, _) {
          final p = deps.purchases;
          final pro = deps.isPro;
          final features = [
            (
              Icons.pets_rounded,
              context.tr(
                'Alle ${characters.length} Figuren',
                'All ${characters.length} characters',
              ),
            ),
            (
              Icons.landscape_rounded,
              context.tr('Alle Themenwelten', 'All scenery worlds'),
            ),
            (
              Icons.hourglass_bottom_rounded,
              context.tr(
                'Regenbogen-, Sanduhr- und Bild-Timer',
                'Rainbow, hourglass and picture timers',
              ),
            ),
            (
              Icons.music_note_rounded,
              context.tr(
                'Zusätzliche Musik und Alarmtöne',
                'More music and alarm sounds',
              ),
            ),
            (
              Icons.photo_rounded,
              context.tr(
                'Eigene Fotos als Timer-Motiv',
                'Your own photos as timer picture',
              ),
            ),
            (
              Icons.bookmarks_rounded,
              context.tr('Eigene Timer-Vorlagen', 'Custom timer templates'),
            ),
            (
              Icons.family_restroom_rounded,
              context.tr(
                'Mehrere lokale Kinderprofile',
                'Several local child profiles',
              ),
            ),
          ];
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                context.tr(
                  'Einmal kaufen, für immer nutzen',
                  'Buy once, keep forever',
                ),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Kein Abo, keine Werbung, keine Verbrauchskäufe. Der kostenlose Timer bleibt vollständig nutzbar.',
                  'No subscription, no ads, no consumables. The free timer stays fully usable.',
                ),
              ),
              const SizedBox(height: 16),
              for (final f in features)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(f.$1, color: const Color(0xFF3B2F7F)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          f.$2,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (pro)
                Card(
                  color: const Color(0xFFE2F7F1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF1FA48B),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr(
                              'Pro ist freigeschaltet. Danke für die Unterstützung!',
                              'Pro is unlocked. Thank you for your support!',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                if (p.state == PurchaseState.unavailable ||
                    p.state == PurchaseState.error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      p.state == PurchaseState.error
                          ? context.tr(
                              'Der Kauf konnte nicht abgeschlossen werden. Es wurde nichts berechnet oder freigeschaltet. Bitte später erneut versuchen.',
                              'The purchase could not be completed. Nothing was charged or unlocked. Please try again later.',
                            )
                          : context.tr(
                              'Der Store ist gerade nicht erreichbar. Die App funktioniert weiter wie gewohnt.',
                              'The store is currently not reachable. The app keeps working as usual.',
                            ),
                      style: const TextStyle(
                        color: Color(0xFFB3261E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (p.state == PurchaseState.pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      context.tr(
                        'Dein Kauf wird noch vom Store bearbeitet. Pro wird automatisch freigeschaltet, sobald er bestätigt ist.',
                        'Your purchase is still being processed. Pro unlocks automatically once confirmed.',
                      ),
                    ),
                  ),
                FilledButton(
                  onPressed:
                      (p.state == PurchaseState.ready ||
                              p.state == PurchaseState.error) &&
                          p.price != null
                      ? p.buy
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A59),
                    minimumSize: const Size.fromHeight(64),
                  ),
                  child:
                      p.state == PurchaseState.purchasing ||
                          p.state == PurchaseState.loading
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          p.price != null
                              ? context.tr(
                                  'Pro freischalten – ${p.price}',
                                  'Unlock Pro – ${p.price}',
                                )
                              : context.tr(
                                  'Pro nicht verfügbar',
                                  'Pro not available',
                                ),
                        ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: p.state == PurchaseState.restoring
                      ? null
                      : p.restore,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    p.state == PurchaseState.restoring
                        ? context.tr('Suche Käufe …', 'Looking for purchases …')
                        : context.tr(
                            'Kauf wiederherstellen',
                            'Restore purchase',
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.tr(
                    'Der Kauf gilt für dieses Store-Konto auf Geräten derselben Plattform (iPhone/iPad oder Android). Plattformübergreifende Freischaltung ist nicht möglich.',
                    'The purchase applies to this store account on devices of the same platform (iPhone/iPad or Android). Cross-platform unlock is not available.',
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6485),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
