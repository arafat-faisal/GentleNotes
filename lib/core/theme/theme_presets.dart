/// Full ThemeData definitions for each [AppThemePreset].
///
/// Every preset provides a completely self-contained [ThemeData] for both
/// light and dark brightness. This is the single source of truth for all
/// visual styling when an aesthetic theme is active — scaffold background,
/// cards, FAB, chips, inputs, AppBar, dialogs, bottom-nav, dividers, etc.
library theme_presets;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry points
// ─────────────────────────────────────────────────────────────────────────────

class ThemePresets {
  ThemePresets._();

  /// Returns the fully-customised [ThemeData] for [preset] in light mode.
  static ThemeData lightThemeData(AppThemePreset preset) =>
      _presetData(preset, Brightness.light);

  /// Returns the fully-customised [ThemeData] for [preset] in dark mode.
  static ThemeData darkThemeData(AppThemePreset preset) =>
      _presetData(preset, Brightness.dark);

  // ── Legacy ColorScheme accessors (kept for gradient helpers in layouts) ────

  static ColorScheme lightScheme(AppThemePreset preset) =>
      _palette(preset, Brightness.light).scheme;

  static ColorScheme darkScheme(AppThemePreset preset) =>
      _palette(preset, Brightness.dark).scheme;

  static List<Color> gradientColors(AppThemePreset preset,
      {bool dark = false}) {
    final p = _palette(preset, dark ? Brightness.dark : Brightness.light);
    return p.gradientColors;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Core builder
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData _presetData(AppThemePreset preset, Brightness brightness) {
    final p = _palette(preset, brightness);
    final isDark = brightness == Brightness.dark;
    final s = p.scheme;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: s,
      scaffoldBackgroundColor: p.scaffoldBg,
      fontFamily: 'Inter',

      // ── AppBar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: p.appBarBg,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: s.onSurface),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: s.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      // ── Cards ───────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: p.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: p.borderColor, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: s.primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Elevated Button ─────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.primary,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── Text Button ─────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── Outlined Button ─────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.primary,
          side: BorderSide(color: p.borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── Chips ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: p.chipBg,
        selectedColor: s.primary.withOpacity(0.18),
        labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: s.onSurface.withOpacity(0.85)),
        shape: StadiumBorder(side: BorderSide(color: p.borderColor)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Input Decoration ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.borderColor)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.borderColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: s.primary, width: 2)),
        hintStyle: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.4),
            fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // ── Bottom Navigation ────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.cardColor,
        elevation: 0,
        selectedItemColor: s.primary,
        unselectedItemColor: s.onSurface.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
      ),

      // ── Dialog ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: p.cardColor,
        elevation: 16,
        shadowColor: s.primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: p.borderColor)),
      ),

      // ── Popup Menu ──────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: p.cardColor,
        elevation: 8,
        shadowColor: s.primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: p.borderColor)),
      ),

      // ── Divider ─────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: p.borderColor, thickness: 1, space: 1),

      // ── Dropdown Menu ───────────────────────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: p.inputFill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: p.borderColor)),
        ),
      ),

      // ── Switch / Checkbox ────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? p.scheme.primary : null),
        trackColor: WidgetStateProperty.resolveWith((st) =>
            st.contains(WidgetState.selected)
                ? p.scheme.primary.withOpacity(0.4)
                : null),
      ),

      // ── Typography ──────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w800,
            color: s.onSurface, letterSpacing: -1),
        headlineLarge: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w700,
            color: s.onSurface, letterSpacing: -0.5),
        headlineMedium: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w600,
            color: s.onSurface, letterSpacing: -0.3),
        titleLarge: TextStyle(
            fontFamily: 'Outfit', fontWeight: FontWeight.w600,
            color: s.onSurface),
        titleMedium: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600,
            color: s.onSurface.withOpacity(0.85)),
        titleSmall: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500,
            color: s.onSurface.withOpacity(0.65)),
        bodyLarge: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.85), height: 1.6),
        bodyMedium: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.65), height: 1.6),
        bodySmall: TextStyle(
            fontFamily: 'Inter',
            color: s.onSurface.withOpacity(0.5), height: 1.5),
        labelLarge: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600,
            color: s.onSurface.withOpacity(0.85)),
        labelMedium: TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w500,
            color: s.onSurface.withOpacity(0.65)),
        labelSmall: TextStyle(
            fontFamily: 'Inter', color: s.onSurface.withOpacity(0.5)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Palette registry — one entry per preset × brightness
  // ─────────────────────────────────────────────────────────────────────────

  static _PresetPalette _palette(AppThemePreset preset, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (preset) {
      // ── Default ─────────────────────────────────────────────────────────
      case AppThemePreset.none:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF8B5CF6),
                  secondary: const Color(0xFFA78BFA),
                  surface: const Color(0xFF10121F),
                  bg: const Color(0xFF090B16),
                  onSurface: const Color(0xFFF1EFF9),
                  outline: const Color(0xFF2D2B45),
                ),
                scaffoldBg: const Color(0xFF090B16),
                appBarBg: const Color(0xFF0D0F1E),
                cardColor: const Color(0xFF10121F),
                borderColor: const Color(0xFF2D2B45),
                chipBg: const Color(0xFF1E1A35),
                inputFill: const Color(0xFF1A172E),
                gradientColors: [const Color(0xFF090B16), const Color(0xFF14102A)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF6366F1),
                  secondary: const Color(0xFF8B5CF6),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF5F3FF),
                  onSurface: const Color(0xFF1A0F3C),
                  outline: const Color(0xFFDDD8F8),
                ),
                scaffoldBg: const Color(0xFFF5F3FF),
                appBarBg: Colors.transparent,
                cardColor: const Color(0xFFFFFFFF),
                borderColor: const Color(0xFFDDD8F8),
                chipBg: const Color(0xFFEDE9FB),
                inputFill: const Color(0xFFF0EDFB),
                gradientColors: [const Color(0xFFEDE9FB), const Color(0xFFF5F3FF)],
              );

      // ── Floral Rose 🌸 ─────────────────────────────────────────────────
      case AppThemePreset.floralRose:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFFF80AB),
                  secondary: const Color(0xFFFF4081),
                  surface: const Color(0xFF240D17),
                  bg: const Color(0xFF1A070F),
                  onSurface: const Color(0xFFFFD9E3),
                  outline: const Color(0xFF5A1A30),
                ),
                scaffoldBg: const Color(0xFF160510),
                appBarBg: const Color(0xFF1A070F),
                cardColor: const Color(0xFF240D17),
                borderColor: const Color(0xFF5A1A30),
                chipBg: const Color(0xFF3A1025),
                inputFill: const Color(0xFF2A0E1C),
                gradientColors: [const Color(0xFF2D0A1A), const Color(0xFF160510)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFFD81B60),
                  secondary: const Color(0xFFFF6B9D),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF0F3),
                  onSurface: const Color(0xFF3B0A1F),
                  outline: const Color(0xFFFFB3C6),
                ),
                scaffoldBg: const Color(0xFFFFF0F3),
                appBarBg: const Color(0xFFFFF8FA),
                cardColor: const Color(0xFFFFF8FA),
                borderColor: const Color(0xFFFFB3C6),
                chipBg: const Color(0xFFFFE4EC),
                inputFill: const Color(0xFFFFF0F5),
                gradientColors: [const Color(0xFFFFE4EC), const Color(0xFFFFF0F3)],
              );

      // ── Cookies & Cream 🍪 ─────────────────────────────────────────────
      case AppThemePreset.cookiesCream:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFD4956A),
                  secondary: const Color(0xFFE8C09A),
                  surface: const Color(0xFF24160C),
                  bg: const Color(0xFF1A0F08),
                  onSurface: const Color(0xFFF5E6D5),
                  outline: const Color(0xFF5A3820),
                ),
                scaffoldBg: const Color(0xFF140C06),
                appBarBg: const Color(0xFF1A0F08),
                cardColor: const Color(0xFF24160C),
                borderColor: const Color(0xFF5A3820),
                chipBg: const Color(0xFF3A2010),
                inputFill: const Color(0xFF2A180C),
                gradientColors: [const Color(0xFF2A1A0A), const Color(0xFF140C06)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF7B4F2E),
                  secondary: const Color(0xFFD4956A),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF8F0),
                  onSurface: const Color(0xFF2C1810),
                  outline: const Color(0xFFE8C9A8),
                ),
                scaffoldBg: const Color(0xFFFFF8F0),
                appBarBg: const Color(0xFFFFFBF5),
                cardColor: const Color(0xFFFFFBF5),
                borderColor: const Color(0xFFE8C9A8),
                chipBg: const Color(0xFFFFEDD8),
                inputFill: const Color(0xFFFFF5E8),
                gradientColors: [const Color(0xFFFFEDD8), const Color(0xFFFFF8F0)],
              );

      // ── Sakura 🌺 ──────────────────────────────────────────────────────
      case AppThemePreset.sakura:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFF48FB1),
                  secondary: const Color(0xFFF8BBD0),
                  surface: const Color(0xFF240D18),
                  bg: const Color(0xFF1A0810),
                  onSurface: const Color(0xFFFFD6E7),
                  outline: const Color(0xFF601830),
                ),
                scaffoldBg: const Color(0xFF14060C),
                appBarBg: const Color(0xFF1A0810),
                cardColor: const Color(0xFF240D18),
                borderColor: const Color(0xFF601830),
                chipBg: const Color(0xFF3A1025),
                inputFill: const Color(0xFF2A0E1C),
                gradientColors: [const Color(0xFF2A0E1C), const Color(0xFF14060C)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFFE91E7A),
                  secondary: const Color(0xFFF8BBD0),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF5F8),
                  onSurface: const Color(0xFF3D0A20),
                  outline: const Color(0xFFF48FB1),
                ),
                scaffoldBg: const Color(0xFFFFF5F8),
                appBarBg: const Color(0xFFFFFAFC),
                cardColor: const Color(0xFFFFFAFC),
                borderColor: const Color(0xFFF48FB1),
                chipBg: const Color(0xFFFFDDEC),
                inputFill: const Color(0xFFFFF0F5),
                gradientColors: [const Color(0xFFFFDDEC), const Color(0xFFFFF5F8)],
              );

      // ── Lavender Dream 💜 ──────────────────────────────────────────────
      case AppThemePreset.lavenderDream:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFCE93D8),
                  secondary: const Color(0xFFE1BEE7),
                  surface: const Color(0xFF1A0F24),
                  bg: const Color(0xFF12091A),
                  onSurface: const Color(0xFFEDD9F5),
                  outline: const Color(0xFF5A1F70),
                ),
                scaffoldBg: const Color(0xFF0E0714),
                appBarBg: const Color(0xFF12091A),
                cardColor: const Color(0xFF1A0F24),
                borderColor: const Color(0xFF5A1F70),
                chipBg: const Color(0xFF2D1040),
                inputFill: const Color(0xFF200D30),
                gradientColors: [const Color(0xFF200D30), const Color(0xFF0E0714)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF8E24AA),
                  secondary: const Color(0xFFCE93D8),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF8F0FF),
                  onSurface: const Color(0xFF2A0A3D),
                  outline: const Color(0xFFE1BEE7),
                ),
                scaffoldBg: const Color(0xFFF8F0FF),
                appBarBg: const Color(0xFFFCF5FF),
                cardColor: const Color(0xFFFCF5FF),
                borderColor: const Color(0xFFE1BEE7),
                chipBg: const Color(0xFFEED8FF),
                inputFill: const Color(0xFFF5EAFF),
                gradientColors: [const Color(0xFFEED8FF), const Color(0xFFF8F0FF)],
              );

      // ── Ocean Breeze 🌊 ────────────────────────────────────────────────
      case AppThemePreset.oceanBreeze:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF4FC3F7),
                  secondary: const Color(0xFF81D4FA),
                  surface: const Color(0xFF071A24),
                  bg: const Color(0xFF031218),
                  onSurface: const Color(0xFFCEEDFF),
                  outline: const Color(0xFF0E4D6B),
                ),
                scaffoldBg: const Color(0xFF020C10),
                appBarBg: const Color(0xFF031218),
                cardColor: const Color(0xFF071A24),
                borderColor: const Color(0xFF0E4D6B),
                chipBg: const Color(0xFF0A2A3A),
                inputFill: const Color(0xFF071820),
                gradientColors: [const Color(0xFF082030), const Color(0xFF020C10)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF0277BD),
                  secondary: const Color(0xFF4FC3F7),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFEFF8FF),
                  onSurface: const Color(0xFF002033),
                  outline: const Color(0xFFB3E5FC),
                ),
                scaffoldBg: const Color(0xFFEFF8FF),
                appBarBg: const Color(0xFFF5FBFF),
                cardColor: const Color(0xFFF5FBFF),
                borderColor: const Color(0xFFB3E5FC),
                chipBg: const Color(0xFFD0ECFF),
                inputFill: const Color(0xFFE5F4FF),
                gradientColors: [const Color(0xFFD0ECFF), const Color(0xFFEFF8FF)],
              );

      // ── Midnight Stars 🌙 ──────────────────────────────────────────────
      case AppThemePreset.midnightStars:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF9FA8DA),
                  secondary: const Color(0xFFC5CAE9),
                  surface: const Color(0xFF08081E),
                  bg: const Color(0xFF03030F),
                  onSurface: const Color(0xFFE8EAF6),
                  outline: const Color(0xFF1A1A5E),
                ),
                scaffoldBg: const Color(0xFF02020A),
                appBarBg: const Color(0xFF03030F),
                cardColor: const Color(0xFF08081E),
                borderColor: const Color(0xFF1A1A5E),
                chipBg: const Color(0xFF10103A),
                inputFill: const Color(0xFF0A0A28),
                gradientColors: [const Color(0xFF0A0A28), const Color(0xFF02020A)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF3949AB),
                  secondary: const Color(0xFF7986CB),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF0F0FF),
                  onSurface: const Color(0xFF0A0A2E),
                  outline: const Color(0xFFC5CAE9),
                ),
                scaffoldBg: const Color(0xFFF0F0FF),
                appBarBg: const Color(0xFFF5F5FF),
                cardColor: const Color(0xFFF5F5FF),
                borderColor: const Color(0xFFC5CAE9),
                chipBg: const Color(0xFFDDE0FF),
                inputFill: const Color(0xFFE8E8FF),
                gradientColors: [const Color(0xFFDDE0FF), const Color(0xFFF0F0FF)],
              );

      // ── Cottagecore 🌿 ─────────────────────────────────────────────────
      case AppThemePreset.cottagecore:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFAED581),
                  secondary: const Color(0xFFC5E1A5),
                  surface: const Color(0xFF0F1A08),
                  bg: const Color(0xFF0A1205),
                  onSurface: const Color(0xFFD7ECC0),
                  outline: const Color(0xFF1E4010),
                ),
                scaffoldBg: const Color(0xFF070D04),
                appBarBg: const Color(0xFF0A1205),
                cardColor: const Color(0xFF0F1A08),
                borderColor: const Color(0xFF1E4010),
                chipBg: const Color(0xFF142810),
                inputFill: const Color(0xFF101E0A),
                gradientColors: [const Color(0xFF182810), const Color(0xFF070D04)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF558B2F),
                  secondary: const Color(0xFF8BC34A),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF4FAF0),
                  onSurface: const Color(0xFF1A2B0A),
                  outline: const Color(0xFFC5E1A5),
                ),
                scaffoldBg: const Color(0xFFF4FAF0),
                appBarBg: const Color(0xFFF8FCF4),
                cardColor: const Color(0xFFF8FCF4),
                borderColor: const Color(0xFFC5E1A5),
                chipBg: const Color(0xFFD8EEC8),
                inputFill: const Color(0xFFEBF5E0),
                gradientColors: [const Color(0xFFD8EEC8), const Color(0xFFF4FAF0)],
              );

      // ── Candy Pop 🍬 ──────────────────────────────────────────────────
      case AppThemePreset.candyPop:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFFF80CE),
                  secondary: const Color(0xFFFFB3E6),
                  surface: const Color(0xFF240A1E),
                  bg: const Color(0xFF1A0515),
                  onSurface: const Color(0xFFFFD9F3),
                  outline: const Color(0xFF7A0F60),
                ),
                scaffoldBg: const Color(0xFF12030E),
                appBarBg: const Color(0xFF1A0515),
                cardColor: const Color(0xFF240A1E),
                borderColor: const Color(0xFF7A0F60),
                chipBg: const Color(0xFF380A2E),
                inputFill: const Color(0xFF280820),
                gradientColors: [const Color(0xFF300820), const Color(0xFF12030E)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFFE91E8C),
                  secondary: const Color(0xFFFF80CE),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFFFF0FB),
                  onSurface: const Color(0xFF3D0030),
                  outline: const Color(0xFFFFB3E6),
                ),
                scaffoldBg: const Color(0xFFFFF0FB),
                appBarBg: const Color(0xFFFFF5FD),
                cardColor: const Color(0xFFFFF5FD),
                borderColor: const Color(0xFFFFB3E6),
                chipBg: const Color(0xFFFFD0F0),
                inputFill: const Color(0xFFFFE8F8),
                gradientColors: [const Color(0xFFFFD0F0), const Color(0xFFFFF0FB)],
              );

      // ── Matcha Latte 🍵 ────────────────────────────────────────────────
      case AppThemePreset.matchaLatte:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFFB5CC8E),
                  secondary: const Color(0xFFC5D99E),
                  surface: const Color(0xFF131F0B),
                  bg: const Color(0xFF0D1508),
                  onSurface: const Color(0xFFD9EDBB),
                  outline: const Color(0xFF2A4A12),
                ),
                scaffoldBg: const Color(0xFF080E05),
                appBarBg: const Color(0xFF0D1508),
                cardColor: const Color(0xFF131F0B),
                borderColor: const Color(0xFF2A4A12),
                chipBg: const Color(0xFF1A2E0A),
                inputFill: const Color(0xFF101A08),
                gradientColors: [const Color(0xFF1A2E0A), const Color(0xFF080E05)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF689F38),
                  secondary: const Color(0xFFA5C461),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF5F8F0),
                  onSurface: const Color(0xFF1A2908),
                  outline: const Color(0xFFDCEDC8),
                ),
                scaffoldBg: const Color(0xFFF5F8F0),
                appBarBg: const Color(0xFFF9FBF5),
                cardColor: const Color(0xFFF9FBF5),
                borderColor: const Color(0xFFDCEDC8),
                chipBg: const Color(0xFFD8ECC0),
                inputFill: const Color(0xFFECF5E0),
                gradientColors: [const Color(0xFFD8ECC0), const Color(0xFFF5F8F0)],
              );

      // ── Cloud Pastel ☁️ ────────────────────────────────────────────────
      case AppThemePreset.cloudPastel:
        return isDark
            ? _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.dark,
                  primary: const Color(0xFF90B0E8),
                  secondary: const Color(0xFFB3C6F0),
                  surface: const Color(0xFF0E1726),
                  bg: const Color(0xFF080F1A),
                  onSurface: const Color(0xFFD6E4FF),
                  outline: const Color(0xFF1A2E5C),
                ),
                scaffoldBg: const Color(0xFF050A12),
                appBarBg: const Color(0xFF080F1A),
                cardColor: const Color(0xFF0E1726),
                borderColor: const Color(0xFF1A2E5C),
                chipBg: const Color(0xFF102040),
                inputFill: const Color(0xFF0C1830),
                gradientColors: [const Color(0xFF102040), const Color(0xFF050A12)],
              )
            : _PresetPalette(
                scheme: _scheme(
                  brightness: Brightness.light,
                  primary: const Color(0xFF5472C4),
                  secondary: const Color(0xFFB3C6F0),
                  surface: const Color(0xFFFFFFFF),
                  bg: const Color(0xFFF0F5FF),
                  onSurface: const Color(0xFF0D1A40),
                  outline: const Color(0xFFBFD0F5),
                ),
                scaffoldBg: const Color(0xFFF0F5FF),
                appBarBg: const Color(0xFFF5F8FF),
                cardColor: const Color(0xFFF5F8FF),
                borderColor: const Color(0xFFBFD0F5),
                chipBg: const Color(0xFFD5E5FF),
                inputFill: const Color(0xFFE5EEFF),
                gradientColors: [const Color(0xFFD5E5FF), const Color(0xFFF0F5FF)],
              );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static ColorScheme _scheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color surface,
    required Color bg,
    required Color onSurface,
    required Color outline,
  }) {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      secondary: secondary,
      onSecondary: brightness == Brightness.dark ? Colors.black : Colors.white,
      tertiary: secondary,
      onTertiary: brightness == Brightness.dark ? Colors.black : Colors.white,
      error: brightness == Brightness.dark
          ? const Color(0xFFEF9A9A)
          : const Color(0xFFE53935),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      background: bg,
      onBackground: onSurface,
      surfaceContainerHighest: bg,
      outline: outline,
      outlineVariant: outline.withOpacity(0.5),
      shadow: Colors.black.withOpacity(0.08),
      scrim: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: secondary,
      surfaceTint: primary.withOpacity(0.05),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal data class
// ─────────────────────────────────────────────────────────────────────────────

class _PresetPalette {
  final ColorScheme scheme;
  final Color scaffoldBg;
  final Color appBarBg;
  final Color cardColor;
  final Color borderColor;
  final Color chipBg;
  final Color inputFill;
  final List<Color> gradientColors;

  const _PresetPalette({
    required this.scheme,
    required this.scaffoldBg,
    required this.appBarBg,
    required this.cardColor,
    required this.borderColor,
    required this.chipBg,
    required this.inputFill,
    required this.gradientColors,
  });
}
