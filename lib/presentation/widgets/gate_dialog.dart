import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/deps.dart';
import '../../data/parental_gate.dart';
import '../theme.dart';

/// Zeigt die Elternsicherung. Gibt true zurück, wenn bestanden.
/// Pflicht vor: Kaufvorgängen, Elternbereich, Beenden gesperrter Timer.
Future<bool> requireParent(BuildContext context, {String? reason}) async {
  final deps = AppScope.of(context);
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _GateDialog(gate: deps.gate, reason: reason),
  );
  return ok ?? false;
}

class _GateDialog extends StatefulWidget {
  const _GateDialog({required this.gate, this.reason});
  final ParentalGateService gate;
  final String? reason;

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  final _ctrl = TextEditingController();
  GateChallenge? _challenge;
  bool _hasPin = false;
  bool _ready = false;
  String? _error;
  int _lockMs = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _hasPin = await widget.gate.hasPin();
    _challenge = widget.gate.newChallenge();
    _lockMs = await widget.gate.lockedForMs();
    if (_lockMs > 0) _startLockTimer();
    if (mounted) setState(() => _ready = true);
  }

  void _startLockTimer() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) async {
      final r = await widget.gate.lockedForMs();
      if (!mounted) return;
      setState(() => _lockMs = r);
      if (r <= 0) _tick?.cancel();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    final res = _hasPin
        ? await widget.gate.checkPin(text)
        : await widget.gate.checkAnswer(_challenge!, int.tryParse(text));
    if (!mounted) return;
    switch (res) {
      case GateResult.ok:
        Navigator.of(context).pop(true);
      case GateResult.wrong:
        setState(() {
          _error = context.tr(
            'Leider falsch. Bitte noch einmal versuchen.',
            'Not correct. Please try again.',
          );
          _ctrl.clear();
          if (!_hasPin) _challenge = widget.gate.newChallenge();
        });
      case GateResult.lockedOut:
        _lockMs = await widget.gate.lockedForMs();
        _startLockTimer();
        if (mounted) {
          setState(() {
            _error = null;
            _ctrl.clear();
          });
        }
    }
  }

  Future<void> _forgot() async {
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RecoveryDialog(gate: widget.gate),
    );
    if (done == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final locked = _lockMs > 0;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Semantics(
        header: true,
        child: Text(
          context.tr('Nur für Erwachsene', 'Grown-ups only'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      content: !_ready
          ? const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.reason != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(widget.reason!),
                  ),
                if (locked)
                  Text(
                    context.tr(
                      'Zu viele Fehlversuche. Bitte in ${(_lockMs / 1000).ceil()} Sekunden erneut versuchen.',
                      'Too many attempts. Please try again in ${(_lockMs / 1000).ceil()} seconds.',
                    ),
                  )
                else ...[
                  Text(
                    _hasPin
                        ? context.tr(
                            'Bitte den Eltern-PIN eingeben.',
                            'Please enter the parent PIN.',
                          )
                        : (context.isDe
                              ? _challenge!.promptDe()
                              : _challenge!.promptEn()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: _hasPin,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ],
            ),
      actions: [
        if (_ready && _hasPin)
          TextButton(
            onPressed: _forgot,
            child: Text(context.tr('PIN vergessen?', 'Forgot PIN?')),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('Abbrechen', 'Cancel')),
        ),
        if (_ready && !locked)
          FilledButton(onPressed: _submit, child: Text(context.tr('OK', 'OK'))),
      ],
    );
  }
}

class _RecoveryDialog extends StatefulWidget {
  const _RecoveryDialog({required this.gate});
  final ParentalGateService gate;
  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  final _ctrl = TextEditingController();
  late GateChallenge _c;
  bool _waiting = false;
  Timer? _t;
  int _remain = 0;

  @override
  void initState() {
    super.initState();
    widget.gate.startRecovery();
    _c = widget.gate.newChallenge();
  }

  @override
  void dispose() {
    _t?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = int.tryParse(_ctrl.text.trim()) == _c.answer;
    _ctrl.clear();
    if (!ok) {
      setState(() => _c = widget.gate.newChallenge());
      return;
    }
    if (widget.gate.recordRecoverySolved()) {
      setState(() {
        _waiting = true;
        _remain = widget.gate.recoveryRemainingMs();
      });
      _t = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _remain = widget.gate.recoveryRemainingMs());
        if (_remain <= 0) _t?.cancel();
      });
    } else {
      setState(() => _c = widget.gate.newChallenge());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('PIN zurücksetzen', 'Reset PIN')),
      content: _waiting
          ? Text(
              _remain > 0
                  ? context.tr(
                      'Bitte noch ${(_remain / 1000).ceil()} Sekunden warten …',
                      'Please wait ${(_remain / 1000).ceil()} more seconds …',
                    )
                  : context.tr(
                      'Der PIN kann jetzt entfernt werden. Danach kann ein neuer PIN gesetzt werden.',
                      'The PIN can now be removed. You can then set a new one.',
                    ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(
                    'Aufgabe ${widget.gate.recoverySolved + 1} von ${ParentalGateService.recoveryChallenges}',
                    'Task ${widget.gate.recoverySolved + 1} of ${ParentalGateService.recoveryChallenges}',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.isDe ? _c.promptDe() : _c.promptEn(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr('Abbrechen', 'Cancel')),
        ),
        if (!_waiting)
          FilledButton(
            onPressed: _submit,
            child: Text(context.tr('Weiter', 'Next')),
          ),
        if (_waiting && _remain <= 0)
          FilledButton(
            onPressed: () async {
              final ok = await widget.gate.completeRecovery();
              if (context.mounted) Navigator.of(context).pop(ok);
            },
            child: Text(context.tr('PIN entfernen', 'Remove PIN')),
          ),
      ],
    );
  }
}
