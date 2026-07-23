import 'package:flutter/material.dart';

/// "Digital Ledger" web palette — warm paper, ink navy, brass accents.
///
/// Web-only tokens. The mobile palette in `core/theme/app_theme.dart`
/// (BsColors) stays untouched; this layer gives the web app its own
/// editorial voice while keeping the navy brand anchor.
abstract final class WebPalette {
  // ── Paper surfaces ──────────────────────────────────────────────
  /// Scaffold canvas — warm ledger paper.
  static const paper = Color(0xFFF7F4EC);

  /// Recessed areas: hover tints, wells, skeleton base.
  static const paperDeep = Color(0xFFEFEBDF);

  /// Raised card surface — warm white.
  static const card = Color(0xFFFFFDF8);

  /// Strongest paper tone, used for sticky header rows.
  static const cardBright = Color(0xFFFFFEFA);

  // ── Ink ─────────────────────────────────────────────────────────
  /// Primary text — near-black navy ink.
  static const ink = Color(0xFF17202E);

  /// Secondary text.
  static const inkSoft = Color(0xFF57606E);

  /// Tertiary text, placeholders, disabled.
  static const inkFaint = Color(0xFF8B91A0);

  // ── Hairlines ───────────────────────────────────────────────────
  /// Default border — warm hairline.
  static const hairline = Color(0xFFE4DECF);

  /// Emphasized border (hover, focused cards).
  static const hairlineStrong = Color(0xFFD4CCB8);

  // ── Brand navy ──────────────────────────────────────────────────
  /// Primary actions — the established brand navy.
  static const navy = Color(0xFF00236F);
  static const navyHover = Color(0xFF0B2F86);
  static const navyPressed = Color(0xFF001A54);

  /// Tinted navy wash for selected states.
  static const navyWash = Color(0x0D00236F);

  // ── Ink rail (sidebar) ──────────────────────────────────────────
  /// Sidebar background — deep ink navy.
  static const rail = Color(0xFF0E1B2C);

  /// Sidebar hover / raised surface.
  static const railRaised = Color(0xFF18293E);

  /// Sidebar hairline.
  static const railLine = Color(0x14FFFFFF);

  /// Muted text on the rail.
  static const railText = Color(0xFF93A0B4);

  /// Full-strength text on the rail.
  static const railTextBright = Color(0xFFF2EFE6);

  // ── Brass accent ────────────────────────────────────────────────
  /// Signature brass — used sparingly for marks, ticks, focus moments.
  static const brass = Color(0xFFAE8126);

  /// Bright brass for the dark rail.
  static const brassBright = Color(0xFFDBA94A);

  /// Deep brass for small text on paper.
  static const brassDeep = Color(0xFF8A6614);

  /// Soft brass wash.
  static const brassWash = Color(0xFFF2E8D2);

  // ── Status (harmonized with paper) ──────────────────────────────
  static const success = Color(0xFF0E6B45);
  static const successWash = Color(0xFFE3EFE6);
  static const danger = Color(0xFFAF2B20);
  static const dangerWash = Color(0xFFF7E5E1);
  static const warning = Color(0xFF8F5B10);
  static const warningWash = Color(0xFFF6ECD8);
  static const info = Color(0xFF264191);
  static const infoWash = Color(0xFFE5EAF6);

  // ── Shadows (ink-tinted, never pure black) ──────────────────────
  static const shadowInk = Color(0xFF2A2416);

  /// Level 1 — resting cards: barely-there lift.
  static const cardShadow = [
    BoxShadow(color: Color(0x0A2A2416), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Level 2 — KPI tiles / hover lift.
  static const metricShadow = [
    BoxShadow(
      color: Color(0x122A2416),
      blurRadius: 14,
      offset: Offset(0, 5),
      spreadRadius: -2,
    ),
    BoxShadow(color: Color(0x082A2416), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Level 3 — modals / overlays.
  static const modalShadow = [
    BoxShadow(
      color: Color(0x1F2A2416),
      blurRadius: 32,
      offset: Offset(0, 12),
      spreadRadius: -6,
    ),
    BoxShadow(color: Color(0x0A2A2416), blurRadius: 8, offset: Offset(0, 3)),
  ];

  // ── Gradients ───────────────────────────────────────────────────
  /// Sidebar depth — a whisper of vertical falloff on the ink rail.
  static const railGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101F33), Color(0xFF0C1826)],
  );

  /// Login brand panel — deep navy with a warm falloff at the foot.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A1B33), Color(0xFF00236F), Color(0xFF0A1B33)],
    stops: [0.0, 0.55, 1.0],
  );
}
