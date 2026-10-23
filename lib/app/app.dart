import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../presentation/painters/hero_painter.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/onboarding_screen.dart';
import '../presentation/theme.dart';
import 'deps.dart';

class TinyTaktApp extends StatelessWidget {
  const TinyTaktApp({super.key, required this.deps});
  final AppDeps deps;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      deps: deps,
      child: MaterialApp(
        title: 'TinyTakt',
        debugShowCheckedModeBanner: false,
        theme: Brand.theme(),
        supportedLocales: const [Locale('de'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (l, supported) =>
            (l != null && l.languageCode == 'de')
            ? const Locale('de')
            : const Locale('en'),
        home: _Root(deps: deps),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({required this.deps});
  final AppDeps deps;
  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _splash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_splash) return const _Splash();
    if (!widget.deps.settings.onboardingDone)
      return OnboardingScreen(onDone: () => setState(() {}));
    return const HomeScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Brand.indigo,
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Semantics(
              label: 'Takti',
              child: CustomPaint(painter: HeroPainter(t: 0.4)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'TinyTakt',
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Mein kleiner Zeitheld', 'My little time hero'),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
