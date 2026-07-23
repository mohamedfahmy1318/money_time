import 'package:flutter/material.dart';

/// Raw brand palette, taken directly from the Figma design.
///
/// Widgets should normally read colours through `context.colors` /
/// `context.appColors`. Use these constants only when defining the theme
/// itself, or for brand gradients that have no `ColorScheme` equivalent.
abstract final class AppColors {
  AppColors._();

  // ── Brand — emerald ────────────────────────────────────────────────────────
  /// Primary brand colour. Active indicator, icon accents, button base.
  static const Color primary = Color(0xFF10B981);

  /// Gradient start on the primary CTA.
  static const Color primaryLight = Color(0xFF34D399);

  /// Gradient end on the primary CTA.
  static const Color primaryDark = Color(0xFF059669);

  /// Splash gradient midpoint.
  static const Color primaryMid = Color(0xFF0B8C63);

  /// Splash gradient end — deepest brand shade.
  static const Color primaryDeep = Color(0xFF065F46);

  /// Soft mint halo behind onboarding illustrations; also the tonal fill of a
  /// selected list row.
  static const Color primarySoft = Color(0xFFE9FBF3);

  /// Text/icon colour on top of [primarySoft].
  static const Color primaryOnSoft = Color(0xFF0E7A54);

  /// Muted mint used for text on the brand gradient (splash tagline).
  static const Color onPrimaryMuted = Color(0xFFD6F5E8);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  /// Page background.
  static const Color background = Color(0xFFF4F7F9);

  /// Primary text / near-black ink.
  static const Color ink = Color(0xFF0B1220);

  /// Secondary text, captions, inactive labels.
  static const Color textMuted = Color(0xFF7A8AA0);

  /// Hairlines, inactive page dots, dividers.
  static const Color divider = Color(0xFFEAF0F4);

  /// Input field outline (slightly stronger than [divider]).
  static const Color inputBorder = Color(0xFFE2E8F0);

  /// Placeholder / hint text inside inputs.
  static const Color hint = Color(0xFF9AA8B8);

  // ── Supporting palette ─────────────────────────────────────────────────────
  /// Slate — neutral secondary from the brand sheet.
  static const Color slate = Color(0xFF94A3B8);

  /// Light neutral fill from the brand sheet.
  static const Color slateLight = Color(0xFFE5E7EB);

  /// Blue accent from the brand sheet. Reserved for dashboard surfaces —
  /// the onboarding flow is emerald-only.
  static const Color accent = Color(0xFF2563EB);

  /// Amber highlight used inside illustrations (star, add button).
  static const Color amber = Color(0xFFFBBF24);
}

/// Brand gradients. Kept beside the palette so both stay in sync.
abstract final class AppGradients {
  AppGradients._();

  /// Primary CTA — 135° emerald sweep.
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.primaryDark],
  );

  /// Full-bleed splash background — 160° three-stop emerald.
  static const LinearGradient splash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.primary,
      AppColors.primaryMid,
      AppColors.primaryDeep,
    ],
    stops: [0.0, 0.55, 1.0],
  );
}
