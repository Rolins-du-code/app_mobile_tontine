// couleur et style de l'application
import 'package:flutter/material.dart';

class AppColors {
  // Couleur principale de l'application
  static const Color primary = Color(0xFF2563EB); // Bleu vif
  static const Color primaryLight = Color(0xFF4F8BFF); // Bleu clair
  static const Color accent = Color(0xFFF2A900); // or

  // Statuts
  static const Color success = Color(0xFF16A34A); // vert
  static const Color danger = Color(0xFFE11D48); // rouge
  static const Color successBg = Color.fromARGB(255, 230, 247, 236); // vert clair
  static const Color dangerBg = Color.fromARGB(255, 252, 237, 241); // rouge clair

  // Neutres (mode claire)
  static const Color background = Color.fromARGB(255, 226, 234, 246); // gris clair
  static const Color card = Color(0xFFFFFFFF); // blanc
  static const Color textDark = Color(0xFF1A2330); // gris fonce
  static const Color muted = Color(0xFF67738A); // gris moyen
  static const Color border = Color.fromARGB(255, 211, 224, 243); // gris clair
}

class AppTheme {
  // MODE CLAIRE DE L'APPLICATION
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color.fromARGB(255, 234, 240, 249),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      cardColor: AppColors.card,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(  // titres principaux
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineMedium: TextStyle(  // titres secondaires
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyMedium: TextStyle(  // texte normal
          fontSize: 14,
          color: AppColors.textDark,
        ),
        bodySmall: TextStyle(  // texte secondaire
          fontSize: 12,
          color: AppColors.muted,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        // style des champs de saisie
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(  // style des bordures
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder( // bordure quand le champ est actif
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(  // bordure quand le champ est focus
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // MODE SOMBRE DE L'APPLICATION
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F15), // gris fonce
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      cardColor: const Color(0xFF1C2632), // gris fonce pour les cartes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color.fromARGB(255, 219, 231, 246), // texte clair en mode sombre
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color.fromARGB(255, 193, 199, 208), // texte clair en mode sombre
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Color(0XFFEDF1F6), // texte clair en mode sombre
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: Color(0XFFEDF1F6), // texte secondaire en mode sombre
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData( // style des boutons en mode sombre
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B9BFF), // bleu clair pour les boutons en mode sombre
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
