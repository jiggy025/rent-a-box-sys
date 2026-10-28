import 'package:flutter/material.dart';

/// The bundled font family (declared in pubspec.yaml under `fonts:`).
const appFontFamily = 'DM Sans';

/// Espasyo's colours in one place. Screens read these through the theme, or directly
/// for the few things the theme has no slot for (a vacant box, a money figure).
///
/// The look is a counter tool: white surfaces on a cool grey ground, near-black ink,
/// one Espasyo amber for the action that matters, green only for "vacant, ready to rent".
class AppColors {
  const AppColors._();

  static const ground = Color(0xFFF3F4F6); // the screen behind the cards
  static const surface = Color(0xFFFFFFFF); // cards, sheets, inputs
  static const surfaceMuted = Color(0xFFF8F9FA); // a quiet panel inside a card
  static const ink = Color(0xFF15171C); // headings, money
  static const ink2 = Color(0xFF3A3F4A); // body text
  static const muted = Color(0xFF667080); // labels, secondary lines
  static const line = Color(0xFFE2E5EA); // hairlines between rows, card edges
  static const lineStrong = Color(0xFFC9CED6); // input borders

  static const accent = Color(0xFF9A5418); // Espasyo amber, deep enough for white text on it
  static const accentSoft = Color(0xFFFBF1E6); // a wash of the accent behind a highlight
  static const vacant = Color(0xFF1E7A4C); // a box that is free to rent
  static const vacantSoft = Color(0xFFE7F4EC);
  static const danger = Color(0xFFB3261E);
}

/// Money and box numbers line up in columns when every digit is the same width.
const tabularFigures = [FontFeature.tabularFigures()];

ThemeData buildAppTheme() {
  // A text theme already set in the bundled family, so every weight below picks its own font file
  final base = ThemeData(useMaterial3: true, fontFamily: appFontFamily).textTheme;
  final textTheme = base
      .apply(bodyColor: AppColors.ink2, displayColor: AppColors.ink)
      .copyWith(
        headlineLarge: base.headlineLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          fontFeatures: tabularFigures,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          fontFeatures: tabularFigures,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          fontFeatures: tabularFigures,
        ),
        titleLarge: base.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: base.titleMedium?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        bodySmall: base.bodySmall?.copyWith(color: AppColors.muted),
      );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.muted,
    outline: AppColors.lineStrong,
    outlineVariant: AppColors.line,
    error: AppColors.danger,
  );

  // Every button and field is at least 52px tall: this is used at a counter, often one-handed
  const controlHeight = 52.0;
  final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    useMaterial3: true,
    fontFamily: appFontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.ground,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.ground,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: controlShape,
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: controlShape,
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.lineStrong),
        textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceMuted,
      side: const BorderSide(color: AppColors.line),
      shape: const StadiumBorder(),
      labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.ink2),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: StadiumBorder(),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.muted,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
