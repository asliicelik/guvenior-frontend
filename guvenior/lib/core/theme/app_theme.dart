import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Ana renkler - Peach & Sky
  static const Color peach = Color(0xFFFFB085);
  static const Color sky = Color(0xFF85C9FF);
  static const Color softPeach = Color(0xFFFFCBA4);
  static const Color softSky = Color(0xFFB8E0FF);
  static const Color deepNavy = Color(0xFF0D1117);
  static const Color darkCard = Color(0xFF161B22);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassWhiteBorder = Color(0x25FFFFFF);

  // Gradient'lar
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [peach, Color(0xFFFF8C69)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [sky, Color(0xFF5BA3E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient peachSkyGradient = LinearGradient(
    colors: [peach, sky],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0D1117), Color(0xFF111827), Color(0xFF0D1117)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Mood renkleri
  static const Color moodHappy = Color(0xFFFFD93D);
  static const Color moodStressed = Color(0xFFFF8C69);
  static const Color moodBored = Color(0xFF85C9FF);
  static const Color moodExcited = Color(0xFFFFB085);
  static const Color moodSad = Color(0xFFA29BFE);
  static const Color moodNeutral = Color(0xFFB2BEC3);

  static var mintGreen;
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.deepNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.peach,
        secondary: AppColors.sky,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
