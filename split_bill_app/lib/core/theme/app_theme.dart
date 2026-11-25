import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color Theme Light (mint, beige, sky)
@immutable
class SplitInColors extends ThemeExtension<SplitInColors> {
  const SplitInColors({
    required this.mint,
    required this.beige,
    required this.sky,
    required this.inputFill,
  });

  final Color mint;
  final Color beige;
  final Color sky;
  final Color inputFill;

  static const light = SplitInColors(
    mint: Color(0xFFE6F2EA),
    beige: Color(0xFFF4E8D6),
    sky: Color(0xFFE5F0FA),
    inputFill: Color(0xFFF1F3F9),
  );

  // Color Theme Dark (mint, beige, sky)
  static const dark = SplitInColors(
    mint: Color(0xFF24332B),
    beige: Color(0xFF3A3326),
    sky: Color(0xFF1F2D3B),
    inputFill: Color(0xFF2A303A),
  );

  @override
  SplitInColors copyWith({Color? mint, Color? beige, Color? sky, Color? inputFill}) =>
      SplitInColors(
        mint: mint ?? this.mint,
        beige: beige ?? this.beige,
        sky: sky ?? this.sky,
        inputFill: inputFill ?? this.inputFill,
      );

  @override
  SplitInColors lerp(ThemeExtension<SplitInColors>? other, double t) {
    if (other is! SplitInColors) return this;
    return SplitInColors(
      mint: Color.lerp(mint, other.mint, t)!,
      beige: Color.lerp(beige, other.beige, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const _charcoal = Color(0xFF1E232C);
  static const _sage = Color(0xFF4B6353);

  static final ColorScheme _lightScheme = const ColorScheme.light(
    primary: _charcoal,
    onPrimary: Colors.white,
    secondary: _sage,
    onSecondary: Colors.white,
    primaryContainer: Color(0xFFE6F2EA),
    onPrimaryContainer: _charcoal,
    tertiaryContainer: Color(0xFFF4E8D6),
    surface: Colors.white,
    onSurface: _charcoal,
    surfaceContainerHighest: Color(0xFFF1F3F9),
    error: Color(0xFFB91C1C),
    errorContainer: Color(0xFFFEE2E2),
  );

  static final ColorScheme _darkScheme = const ColorScheme.dark(
    primary: Color(0xFFE6F2EA),
    onPrimary: _charcoal,
    secondary: Color(0xFF8FB39D),
    onSecondary: _charcoal,
    primaryContainer: Color(0xFF24332B),
    onPrimaryContainer: Color(0xFFE6F2EA),
    tertiaryContainer: Color(0xFF3A3326),
    surface: Color(0xFF14171C),
    onSurface: Color(0xFFF1F3F9),
    surfaceContainerHighest: Color(0xFF2A303A),
    error: Color(0xFFF87171),
    errorContainer: Color(0xFF4A1D1D),
  );

  static ThemeData get light => _build(_lightScheme, SplitInColors.light);
  static ThemeData get dark => _build(_darkScheme, SplitInColors.dark);

  static ThemeData _build(ColorScheme cs, SplitInColors extra) {
    final base = ThemeData(useMaterial3: true, colorScheme: cs);
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface)
        .copyWith(
          headlineSmall: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w700), // page title
          headlineMedium: GoogleFonts.plusJakartaSans(
              fontSize: 28, fontWeight: FontWeight.w700), // total nominal
          titleMedium: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w600), // section heading
          titleSmall: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600), // card title
          bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14),
          bodySmall: GoogleFonts.plusJakartaSans(fontSize: 13),
          labelSmall: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w500), // badge, caption
        );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: cs.surface,
      extensions: [extra],
      cardTheme: CardThemeData(
        elevation: 0,
        color: extra.mint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: text.titleSmall,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: extra.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: extra.inputFill,
        selectedColor: cs.primary,
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: extra.mint,
        indicatorShape: const StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? cs.secondary : null,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.secondary),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}