import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';

/// "Orchard Modernist" design system, exported from the Stitch project
/// (see `stitch-sync/export/14626018066789175812/DESIGN.md`).
///
/// Light theme only. Emerald greens + orchard-orange accents on clean
/// white surfaces. Inter throughout, tabular numbers for currency.
abstract final class OrchardColors {
  // Brand greens
  static const primary = Color(0xFF22C55E); // core actions, active tabs
  static const pressed = Color(0xFF16A34A); // pressed state
  static const deep = Color(0xFF006E2F); // surface tint / strong primary
  static const pine = Color(0xFF15803D); // icons on tint, success text
  static const forest = Color(0xFF14532D); // high-impact headings
  static const onPrimary = Colors.white;

  // Brand orange
  static const brand = Color(0xFFE65100); // booking / pay CTAs, badges
  static const brandDeep = Color(0xFFA83900);
  static const brandContainer = Color(0xFFFFDBCF);

  // Neutrals
  static const ink = Color(0xFF141B2B); // primary text
  static const slate = Color(0xFF111827); // body copy
  static const muted = Color(0xFF6B7280); // secondary metadata
  static const border = Color(0xFFE5E7EB); // 1px card / input borders
  static const surface = Colors.white;
  static const background = Color(0xFFF9F9FF);

  // Tints
  static const tint50 = Color(0xFFF0FDF4); // card tints
  static const tint100 = Color(0xFFDCFCE7); // icon backdrops, track
  static const tint200 = Color(0xFFBBF7D0); // focus ring, connectors

  // Status
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const success = Color(0xFF16A34A);
  static const info = Color(0xFF2563EB);

  // Status chip pairs (bg, fg) per DESIGN.md
  static const chipDone = (Color(0xFFF0FDF4), Color(0xFF15803D));
  static const chipProgress = (Color(0xFFFFFBEB), Color(0xFFD97706));
  static const chipBad = (Color(0xFFFEF2F2), Color(0xFFDC2626));
  static const chipInfo = (Color(0xFFEFF6FF), Color(0xFF2563EB));
  static const chipIdle = (Color(0xFFF3F4F6), Color(0xFF4B5563));

  /// Resolve a (background, foreground) pair from a status label.
  static (Color, Color) statusPair(String label) {
    final l = label.toLowerCase();
    if (l.contains('complet') ||
        l.contains('paid') ||
        l.contains('success') ||
        l.contains('in stock') ||
        l.contains('active')) {
      return chipDone;
    }
    if (l.contains('progress') || l.contains('partial')) return chipProgress;
    if (l.contains('overdue') ||
        l.contains('cancel') ||
        l.contains('unpaid') ||
        l.contains('out of stock') ||
        l.contains('fail') ||
        l.contains('error')) {
      return chipBad;
    }
    if (l.contains('assign') ||
        l.contains('info') ||
        l.contains('sent') ||
        l.contains('support')) {
      return chipInfo;
    }
    return chipIdle;
  }
}

Color? _parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final clean = hex.replaceAll('#', '').trim();
  if (clean.length == 6) {
    return Color(int.parse('FF$clean', radix: 16));
  } else if (clean.length == 8) {
    return Color(int.parse(clean, radix: 16));
  }
  return null;
}

TextTheme _resolveBaseTextTheme(String? fontFamily, TextTheme baseText) {
  final font = fontFamily?.trim();
  if (font == null || font.isEmpty || font.toLowerCase() == 'inter') {
    return GoogleFonts.interTextTheme(baseText);
  }
  try {
    return GoogleFonts.getTextTheme(font, baseText);
  } catch (_) {
    return GoogleFonts.interTextTheme(baseText);
  }
}

ThemeData buildOrchardTheme([ThemeConfig? config]) {
  final base = ThemeData.light(useMaterial3: true);
  final fontName = (config != null && config.fontFamily.isNotEmpty)
      ? config.fontFamily
      : 'Inter';

  final primary = _parseHex(config?.palette['500']) ?? OrchardColors.primary;
  final pressed = _parseHex(config?.palette['600']) ?? OrchardColors.pressed;
  final pine = _parseHex(config?.palette['700']) ?? OrchardColors.pine;
  final forest = _parseHex(config?.palette['900']) ?? OrchardColors.forest;
  final tint100 = _parseHex(config?.palette['100']) ?? OrchardColors.tint100;

  final text = _resolveBaseTextTheme(fontName, base.textTheme);

  TextStyle scaled(TextStyle? s, double size, FontWeight w, double height,
      {double letter = 0}) {
    return (s ?? const TextStyle()).copyWith(
      fontSize: size,
      fontWeight: w,
      height: height / size,
      letterSpacing: letter,
      color: OrchardColors.ink,
      fontFamily: fontName,
    );
  }

  final textTheme = text.copyWith(
    headlineLarge: scaled(text.headlineLarge, 24, FontWeight.w700, 32,
        letter: -0.48),
    headlineMedium: scaled(text.headlineMedium, 20, FontWeight.w700, 28,
        letter: -0.2),
    headlineSmall: scaled(text.headlineSmall, 18, FontWeight.w600, 24),
    titleMedium: scaled(text.titleMedium, 16, FontWeight.w600, 22),
    titleSmall: scaled(text.titleSmall, 14, FontWeight.w600, 20),
    bodyLarge: scaled(text.bodyLarge, 16, FontWeight.w400, 24),
    bodyMedium: scaled(text.bodyMedium, 14, FontWeight.w400, 20),
    bodySmall: scaled(text.bodySmall, 13, FontWeight.w400, 18),
    labelLarge: scaled(text.labelLarge, 14, FontWeight.w600, 20),
    labelMedium: scaled(text.labelMedium, 12, FontWeight.w500, 16),
    labelSmall: scaled(text.labelSmall, 11, FontWeight.w600, 14,
        letter: 0.22),
  );

  final scheme = ColorScheme.light(
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: tint100,
    onPrimaryContainer: forest,
    secondary: OrchardColors.brand,
    onSecondary: Colors.white,
    secondaryContainer: OrchardColors.brandContainer,
    onSecondaryContainer: OrchardColors.brandDeep,
    tertiary: forest,
    surface: OrchardColors.surface,
    onSurface: OrchardColors.ink,
    surfaceContainerHighest: const Color(0xFFE9EDFF),
    error: const Color(0xFFBA1A1A),
    onError: Colors.white,
    errorContainer: const Color(0xFFFFDAD6),
  );

  const cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
    side: BorderSide(color: OrchardColors.border, width: 1),
  );

  InputBorder inputBorder(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: OrchardColors.background,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: OrchardColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle:
          scaled(text.titleMedium, 20, FontWeight.w700, 28, letter: -0.2),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: cardShape,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontName),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.pressed)
                ? pressed
                : primary),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: pine,
        minimumSize: const Size(64, 48),
        side: BorderSide(color: primary, width: 1.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontName),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: pine,
        textStyle: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, fontFamily: fontName),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: OrchardColors.muted),
      border: inputBorder(OrchardColors.border, 1),
      enabledBorder: inputBorder(OrchardColors.border, 1),
      focusedBorder: inputBorder(primary, 1.5),
      errorBorder: inputBorder(OrchardColors.danger, 1.5),
      focusedErrorBorder: inputBorder(OrchardColors.danger, 1.5),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: OrchardColors.border),
      backgroundColor: Colors.white,
      selectedColor: tint100,
      labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: OrchardColors.ink,
          fontFamily: fontName),
      secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: pine,
          fontFamily: fontName),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStatePropertyAll(
          BorderSide(color: OrchardColors.border, width: 1)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      hintStyle: const WidgetStatePropertyAll(
          TextStyle(color: OrchardColors.muted)),
      constraints: const BoxConstraints(minHeight: 48),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      height: 64,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: fontName)
              .copyWith(
                  color: states.contains(WidgetState.selected)
                      ? primary
                      : OrchardColors.muted)),
      iconTheme: WidgetStateProperty.resolveWith((states) =>
          IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primary
                  : OrchardColors.muted)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: tint100,
    ),
    dividerTheme: const DividerThemeData(color: OrchardColors.border),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: OrchardColors.ink,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12))),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// 22px / 700 currency figures with tabular numbers (no layout jump).
const orchardCurrencyStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 22,
  fontWeight: FontWeight.w700,
  height: 28 / 22,
  fontFeatures: [FontFeature.tabularFigures()],
  color: OrchardColors.ink,
);
