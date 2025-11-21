import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette de couleurs inspirée de Gmail - Élégante et moderne
  static const _primaryBlue = Color(0xFF1A73E8);      // Bleu Gmail
  static const _secondaryBlue = Color(0xFF0B57D0);    // Bleu foncé
  static const _tertiaryTeal = Color(0xFF12B5CB);     // Bleu-vert accent
  static const _errorRed = Color(0xFFD93025);         // Rouge Gmail
  static const _surfaceGrey = Color(0xFFF8F9FA);      // Gris très clair
  static const _outlineGrey = Color(0xFFDADCE0);      // Bordures grises

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    
    // ColorScheme Material 3 - Inspiré de Gmail
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      
      // Couleurs principales
      primary: _primaryBlue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFD2E3FC),
      onPrimaryContainer: Color(0xFF001C3A),
      
      // Couleurs secondaires
      secondary: _secondaryBlue,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1E4FF),
      onSecondaryContainer: Color(0xFF001D36),
      
      // Couleurs tertiaires
      tertiary: _tertiaryTeal,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFB8F0F7),
      onTertiaryContainer: Color(0xFF002022),
      
      // Erreur
      error: _errorRed,
      onError: Colors.white,
      errorContainer: Color(0xFFFCE8E6),
      onErrorContainer: Color(0xFF410E0B),
      
      // Surfaces
      background: Colors.white,
      onBackground: Color(0xFF1A1C1E),
      surface: Colors.white,
      onSurface: Color(0xFF1A1C1E),
      surfaceVariant: _surfaceGrey,
      onSurfaceVariant: Color(0xFF43474E),
      
      // Bordures et contours
      outline: _outlineGrey,
      outlineVariant: Color(0xFFE3E3E3),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      
      // Inverse (pour surfaces sombres sur fond clair)
      inverseSurface: Color(0xFF2E3133),
      onInverseSurface: Color(0xFFF0F0F3),
      inversePrimary: Color(0xFF9ECAFF),
    ),
    
    // Typographie élégante avec Roboto (style Gmail)
    textTheme: GoogleFonts.robotoTextTheme(
      const TextTheme(
        // Display - Très grands titres
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          height: 1.12,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.16,
        ),
        displaySmall: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.22,
        ),
        
        // Headline - Titres de sections
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.25,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          height: 1.29,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          height: 1.33,
        ),
        
        // Title - Titres de cartes et composants
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          height: 1.27,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          height: 1.50,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        
        // Body - Texte de contenu
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          height: 1.50,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          height: 1.43,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          height: 1.33,
        ),
        
        // Label - Boutons et petits labels
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          height: 1.43,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.33,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.45,
        ),
      ),
    ),
    
    // Scaffold
    scaffoldBackgroundColor: Colors.white,
    
    // AppBar moderne
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1C1E),
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 3,
      shadowColor: Color(0x1A000000),
      surfaceTintColor: _surfaceGrey,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1C1E),
        letterSpacing: 0,
      ),
    ),
    
    // Cards avec Material 3
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _outlineGrey, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
    ),
    
    // Boutons Material 3
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _surfaceGrey,
        foregroundColor: _primaryBlue,
        elevation: 1,
        shadowColor: const Color(0x1A000000),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlue,
        side: const BorderSide(color: _outlineGrey, width: 1),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        minimumSize: const Size(64, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryBlue,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(48, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    // TextFields Material 3
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outlineGrey, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _outlineGrey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA0A6),
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF5F6368),
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: const TextStyle(
        color: _primaryBlue,
        fontWeight: FontWeight.w500,
      ),
    ),
    
    // Dividers
    dividerTheme: const DividerThemeData(
      color: _outlineGrey,
      thickness: 1,
      space: 1,
    ),
    
    // Bottom Navigation Bar Material 3
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFD2E3FC),
      elevation: 3,
      shadowColor: const Color(0x1A000000),
      height: 80,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _primaryBlue,
          );
        }
        return const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0xFF5F6368),
        );
      }),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(
            color: _primaryBlue,
            size: 24,
          );
        }
        return const IconThemeData(
          color: Color(0xFF5F6368),
          size: 24,
        );
      }),
    ),
    
    // FAB Material 3
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _tertiaryTeal,
      foregroundColor: Colors.white,
      elevation: 3,
      highlightElevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: _surfaceGrey,
      selectedColor: const Color(0xFFD2E3FC),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xFF1A1C1E),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _outlineGrey, width: 1),
      ),
    ),
    
    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1C1E),
      ),
    ),
    
    // BottomSheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      dragHandleColor: _outlineGrey,
    ),
    
    // Progress Indicator
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _primaryBlue,
      linearTrackColor: Color(0xFFE8F0FE),
      circularTrackColor: Color(0xFFE8F0FE),
    ),
  );
}
