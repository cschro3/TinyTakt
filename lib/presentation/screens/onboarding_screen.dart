import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/deps.dart';
import '../painters/hero_painter.dart';
import '../theme.dart';
import '../widgets/gate_dialog.dart';

/// Kurzes Onboarding: Idee, Auswahl, Hinweis für Eltern (Benachrichtigung).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _page = PageController();
  int _i = 0;
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);
  bool? _permission;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = AppScope.of(context);
    final pages = [
      (
        context.tr('Hallo! Ich bin Takti.', 'Hi! I’m Takti.'),
        context.tr(
          'Ich zeige dir, wie die Zeit vergeht – ganz ohne Uhr lesen.',
          'I show you how time passes – no clock reading needed.',
        ),
      ),
      (
        context.tr('Such dir einen Freund aus', 'Pick a friend'),
        context.tr(
          'Tiere, Dinos, Raketen und mehr begleiten deine Zeit. Der Ring wird kleiner, bis du es geschafft hast.',
          'Animals, dinos, rockets and more join your time. The ring gets smaller until you’re done.',
        ),
      ),
      (
        context.tr('Für Eltern', 'For parents'),
        context.tr(
          'Damit der Timer auch bei geschlossener App klingelt, erlauben Sie bitte Benachrichtigungen. TinyTakt hat keine Werbung und sammelt keine Daten.',
          'So the timer can ring even when the app is closed, please allow notifications. TinyTakt has no ads and collects no data.',
        ),
      ),
    ];
    return Scaffold(
      backgroundColor: Brand.indigo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _t,
                          builder: (_, t, _) => Semantics(
                            label: 'Takti',
                            child: CustomPaint(
                              painter: HeroPainter(t: t),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pages[i].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pages[i].$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                      ),
                      if (i == 2) ...[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            minimumSize: const Size(0, 52),
                          ),
                          icon: Icon(
                            _permission == true
                                ? Icons.check_circle_rounded
                                : Icons.notifications_active_rounded,
                          ),
                          label: Text(
                            _permission == true
                                ? context.tr('Erlaubt', 'Allowed')
                                : context.tr(
                                    'Benachrichtigung erlauben',
                                    'Allow notifications',
                                  ),
                          ),
                          onPressed: () async {
                            if (!await requireParent(context)) return;
                            final ok = await d.timer.notifications
                                .requestPermission();
                            if (mounted) setState(() => _permission = ok);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var k = 0; k < pages.length; k++)
                  Container(
                    margin: const EdgeInsets.all(5),
                    width: k == _i ? 26 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: k == _i ? Brand.sun : Colors.white38,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.coral,
                  minimumSize: const Size.fromHeight(60),
                ),
                onPressed: () {
                  if (_i < pages.length - 1) {
                    _page.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  } else {
                    d.settings.update((s) => s.onboardingDone = true);
                    widget.onDone();
                  }
                },
                child: Text(
                  _i < pages.length - 1
                      ? context.tr('Weiter', 'Next')
                      : context.tr('Los geht’s!', 'Let’s go!'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
