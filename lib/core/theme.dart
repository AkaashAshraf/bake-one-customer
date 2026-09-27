import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same red & white look as the Bake One website.
class Brand {
  Brand._();

  static const red = Color(0xFFE1251B);
  static const redBright = Color(0xFFFF5047);
  static const redDark = Color(0xFFC81E16);
  static const redDeep = Color(0xFFA51A13);
  static const peach = Color(0xFFFF7A52);
  static const ink = Color(0xFF1F1A17);
  static const muted = Color(0xFF5B5552);
  static const faint = Color(0xFF9A928C);
  static const soft = Color(0xFFFFF4F2);
  static const softer = Color(0xFFFFF8F6);
  static const blush = Color(0xFFFFE4E0);
  static const line = Color(0x1AE1251B);
  static const green = Color(0xFF10B981);
  static const greenDark = Color(0xFF059669);
  static const amber = Color(0xFFF59E0B);

  static const redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, Color(0xFFD21F16), redDeep],
  );

  static const buttonGradient = LinearGradient(colors: [red, redBright, redDark]);

  static const productBg = RadialGradient(
    center: Alignment(0, -0.1),
    radius: 0.9,
    colors: [Colors.white, Color(0xFFFFF1EE), blush],
    stops: [0, .55, 1],
  );

  static const discountBg = RadialGradient(
    center: Alignment(0, -0.1),
    radius: 0.9,
    colors: [Colors.white, Color(0xFFECFDF5), Color(0xFFD1FAE5)],
    stops: [0, .6, 1],
  );

  static List<BoxShadow> card = [
    BoxShadow(color: const Color(0xFF3C140A).withOpacity(.10), blurRadius: 28, offset: const Offset(0, 12), spreadRadius: -10),
  ];

  static List<BoxShadow> glow = [
    BoxShadow(color: red.withOpacity(.30), blurRadius: 30, offset: const Offset(0, 14), spreadRadius: -10),
  ];

  static TextStyle display(double size, {Color color = ink, FontWeight weight = FontWeight.w700, FontStyle? style, double? height}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, color: color, fontWeight: weight, fontStyle: style, height: height ?? 1.15, letterSpacing: size >= 20 ? -0.4 : 0);

  static TextStyle eyebrow({Color color = red}) =>
      GoogleFonts.plusJakartaSans(fontSize: 11, letterSpacing: 2.2, fontWeight: FontWeight.w600, color: color);

  static ThemeData theme() {
    final scheme = ColorScheme.fromSeed(seedColor: red, brightness: Brightness.light).copyWith(
      primary: red,
      onPrimary: Colors.white,
      secondary: redDark,
      surface: Colors.white,
      onSurface: ink,
      error: redDark,
    );
    final text = GoogleFonts.plusJakartaSansTextTheme().apply(bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: display(22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Color(0xFFE7E5E4))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: red, width: 1.6)),
        hintStyle: const TextStyle(color: faint),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, letterSpacing: .3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: red,
          side: const BorderSide(color: red, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, letterSpacing: .3),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
