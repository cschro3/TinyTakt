import 'dart:math' as math;
import 'dart:ui';

import 'art_kit.dart';

/// Gefühlslage einer Figur. Bestimmt Mimik und Bewegung.
enum Emotion { calm, greet, cheer, encourage, celebrate, sleepy }

enum EyeMode { open, happy, sleepy, wide, wink }

enum MouthShape { smile, grin, open, o, neutral, sleepy }

/// Momentaufnahme aller animierbaren Parameter einer Figur (Rig-Zustand).
class Pose {
  double breath = 0; // -1..1 (ein-/ausatmen)
  double blink = 0; // 0 offen … 1 zu
  Offset look = Offset.zero; // Blickrichtung (-1..1)
  double headTilt = 0; // Radiant
  double headDy = 0;
  double bodyDy = 0; // Hüpfen
  double squash = 0; // -1 gestreckt … 1 gestaucht
  double lean = 0; // Körperneigung (Radiant)
  double earL = 0, earR = 0; // Ohrwackeln (Radiant)
  double tail = 0; // Schwanzschwung (-1..1)
  double armL = 0, armR = 0; // Arme/Pfoten (Radiant)
  double cheek = 0; // Wangen aufpusten (0..1)
  double glow = 1; // Leuchtstärke (0..1.4)
  double sparkle = 0; // Freudenfunkeln (0..1)
  EyeMode eyes = EyeMode.open;
  MouthShape mouth = MouthShape.smile;
}

/// Charakter-Persönlichkeit steuert Tempo und Eigenheiten der Animation.
class Personality {
  const Personality({
    this.breathRate = 1.6,
    this.breathDepth = 1.0,
    this.blinkEvery = 3.6,
    this.tailRate = 2.2,
    this.tailAmp = 0.5,
    this.earTwitch = 0.4,
    this.curiosity = 0.0,
    this.bounce = 1.0,
    this.glowPulse = 0.0,
    this.winker = false,
    this.seed = 1,
  });
  final double breathRate,
      breathDepth,
      blinkEvery,
      tailRate,
      tailAmp,
      earTwitch,
      curiosity,
      bounce,
      glowPulse;
  final bool winker;
  final int seed;
}

/// Berechnet aus Zeit und Gefühl die Pose. [t] = Laufzeit der Szene, [et] = Sekunden seit Beginn des Gefühls.
Pose computePose(
  Personality p,
  Emotion e,
  double t,
  double et, {
  bool calm = false,
}) {
  final pose = Pose();
  if (calm) {
    // Reduzierte Animation: statische, freundliche Pose
    pose.eyes = e == Emotion.sleepy ? EyeMode.sleepy : EyeMode.open;
    pose.mouth = e == Emotion.celebrate ? MouthShape.grin : MouthShape.smile;
    return pose;
  }
  final ph = p.seed * 1.37;
  // Atmen (Basis für alles)
  pose.breath = math.sin(t * p.breathRate + ph) * p.breathDepth;

  // Blinzeln: kurzer Doppelschlag in unregelmäßigen Abständen
  final cycle =
      p.blinkEvery *
      (1 + 0.3 * math.sin(p.seed + (t / p.blinkEvery).floor() * 1.7));
  final bt = t % cycle;
  if (bt < 0.16) {
    pose.blink = math.sin(bt / 0.16 * math.pi);
  } else if (bt > 0.34 && bt < 0.46 && (t / cycle).floor() % 3 == 0) {
    pose.blink = math.sin((bt - 0.34) / 0.12 * math.pi);
  }

  // Kleine Eigenbewegungen: Blick wandert, Kopf neigt sich leicht
  final lookT = t * 0.35 + ph;
  pose.look = Offset(
    math.sin(lookT * 1.3) * (0.35 + p.curiosity * 0.4),
    math.sin(lookT * 0.9 + 1) * 0.2,
  );
  pose.headTilt = math.sin(t * 0.5 + ph) * (0.025 + p.curiosity * 0.05);
  pose.tail = math.sin(t * p.tailRate + ph) * p.tailAmp;
  final twitch = pulse(t % 5.3, 3.0, 0.35);
  pose.earL = twitch * p.earTwitch * 0.6 + math.sin(t * 0.9 + ph) * 0.02;
  pose.earR =
      pulse((t + 1.9) % 6.1, 4.0, 0.3) * p.earTwitch * 0.6 +
      math.sin(t * 0.8 + ph) * 0.02;
  pose.glow = 1 + math.sin(t * 1.8 + ph) * p.glowPulse;
  pose.squash = -pose.breath * 0.03 * p.breathDepth;
  pose.mouth = MouthShape.smile;

  switch (e) {
    case Emotion.calm:
      if (p.winker && pulse(t % 7.0, 5.5, 0.5) > 0.4) pose.eyes = EyeMode.wink;
      break;
    case Emotion.greet:
      // Winken/Begrüßen: Hüpfer, Pfote hoch, strahlende Augen
      final k = smoothstep(0, 0.2, et) * (1 - smoothstep(1.6, 2.2, et));
      pose.armR = -(0.9 + math.sin(et * 11) * 0.28) * k;
      pose.bodyDy = -pulse(et, 0.0, 0.42) * 0.07 * p.bounce;
      pose.headTilt += 0.08 * k;
      pose.mouth = MouthShape.grin;
      pose.eyes = EyeMode.happy;
      pose.tail = math.sin(t * p.tailRate * 3) * p.tailAmp * 1.4;
      pose.sparkle = k * 0.5;
      break;
    case Emotion.cheer:
      // Freude beim Start: zwei Hüpfer, Ohren hoch
      final k = 1 - smoothstep(1.0, 1.6, et);
      pose.bodyDy =
          -(pulse(et, 0.0, 0.4) + pulse(et, 0.45, 0.4) * 0.8) * 0.1 * p.bounce;
      pose.squash +=
          (pulse(et, 0.35, 0.12) * 0.15 - pulse(et, 0.0, 0.06) * 0.1);
      pose.armL = -0.6 * k;
      pose.armR = -0.6 * k;
      pose.earL += 0.25 * k;
      pose.earR -= 0.25 * k;
      pose.eyes = EyeMode.wide;
      pose.mouth = MouthShape.grin;
      pose.sparkle = k * 0.8;
      pose.glow *= 1 + 0.35 * k;
      break;
    case Emotion.encourage:
      // Ermutigung: Nicken + Daumen-hoch-Pfote + warmes Lächeln
      final k = smoothstep(0, 0.2, et) * (1 - smoothstep(1.4, 2.0, et));
      pose.headDy = math.sin(et * 9) * 0.025 * k;
      pose.armR = -0.75 * k;
      pose.eyes = EyeMode.happy;
      pose.mouth = MouthShape.grin;
      pose.glow *= 1 + 0.25 * k;
      pose.sparkle = k * 0.6;
      break;
    case Emotion.celebrate:
      // Begeisterung: Jubelsprünge, die nach ca. 3 s sanft abklingen
      final decay = 1 - smoothstep(2.6, 4.0, et) * 0.7;
      final hop = (math.sin(et * 7.5)).abs();
      pose.bodyDy = -hop * 0.13 * decay * p.bounce;
      pose.squash += (hop < 0.15 ? 0.12 : -0.05) * decay;
      pose.armL = -1.0 * decay + math.sin(et * 15) * 0.15;
      pose.armR = -1.0 * decay - math.sin(et * 15) * 0.15;
      pose.earL += 0.3 * decay;
      pose.earR -= 0.3 * decay;
      pose.eyes = EyeMode.happy;
      pose.mouth = MouthShape.open;
      pose.sparkle = decay;
      pose.glow *= 1 + 0.4 * decay;
      pose.tail = math.sin(t * p.tailRate * 3.5) * p.tailAmp * 1.6;
      pose.lean = math.sin(et * 7.5 * 0.5) * 0.06 * decay;
      break;
    case Emotion.sleepy:
      pose.eyes = EyeMode.sleepy;
      pose.mouth = MouthShape.sleepy;
      pose.breath *= 1.4;
      pose.headTilt = 0.1 + math.sin(t * 0.4) * 0.02;
      pose.headDy = 0.03;
      pose.blink = 0;
      pose.tail *= 0.3;
      pose.glow = 0.55 + math.sin(t * 1.0) * 0.1;
      break;
  }
  return pose;
}
