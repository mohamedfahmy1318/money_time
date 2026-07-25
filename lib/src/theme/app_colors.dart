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
  static const Color primary = Color(0xFF94A3B8);

  /// Gradient start on the primary CTA.
  static const Color primaryLight = Color(0xFF94A3B8);

  /// Gradient end on the primary CTA.
  static const Color primaryDark = Color(0xFF94A3B8);

  /// Splash gradient midpoint.
  static const Color primaryMid = Color(0xFF94A3B8);

  /// Splash gradient end — deepest brand shade.
  static const Color primaryDeep = Color(0xFF94A3B8);

  /// Soft mint halo behind onboarding illustrations; also the tonal fill of a
  /// selected list row.
  static const Color primarySoft = Color(0xFFE9FBF3);

  /// Text/icon colour on top of [primarySoft].
  static const Color primaryOnSoft = Color(0xFF94A3B8);

  /// Muted mint used for text on the brand gradient (splash tagline).
  static const Color onPrimaryMuted = Color(0xFFD6F5E8);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  /// Page background.
  static const Color background = Color(0xFFF8FAFC);

  /// Primary text / near-black ink.
  static const Color ink = Color(0xFF1F2937);

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

  /// Deep amber — end stop of the budget "warning" progress sweep.
  static const Color amberDeep = Color(0xFFF59E0B);

  /// Light red — start stop of the budget "over" progress sweep.
  static const Color errorLight = Color(0xFFF87171);

  /// Softened red used for weekend (Saturday) dates on the calendar grid.
  static const Color softRed = Color(0xFFEF6A5E);

  /// Deep slate header bar on the transaction filter screen.
  static const Color slateDeep = Color(0xFF2E3B57);

  // ── Category tile tints ──────────────────────────────────────────────────
  /// Mint tile — reuses [primarySoft].
  static const Color tintMint = primarySoft;

  /// Blue tile.
  static const Color tintBlue = Color(0xFFE7F0FE);

  /// Orange tile.
  static const Color tintOrange = Color(0xFFFEF3E2);
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

  /// Emerald hero-card sweep (budget card, currency preview).
  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primary,
      AppColors.primaryMid,
      AppColors.primaryDeep,
    ],
    stops: [0.0, 0.7, 1.0],
  );
}
