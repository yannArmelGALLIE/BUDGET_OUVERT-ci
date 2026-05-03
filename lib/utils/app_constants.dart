// lib/utils/app_constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - dark forest green
  static const Color primary = Color(0xFF1A4731);
  static const Color primaryDark = Color(0xFF0F2E1E);
  static const Color primaryLight = Color(0xFF2D6B4A);
  static const Color primarySurface = Color(0xFFE8F5EE);

  // Accent - orange/amber (elephant logo color)
  static const Color accent = Color(0xFFE07B3A);
  static const Color accentLight = Color(0xFFF4A261);

  // Semantic colors
  static const Color success = Color(0xFF2D9B6B);
  static const Color warning = Color(0xFFE07B3A);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3B82F6);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7FAF8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5EDE9);
  static const Color inputBg = Color(0xFFF1F5F3);

  // Text
  static const Color textPrimary = Color(0xFF1A2E24);
  static const Color textSecondary = Color(0xFF6B8C7A);
  static const Color textHint = Color(0xFFAABFB4);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status chips
  static const Color statusLivre = Color(0xFF2D9B6B);
  static const Color statusEnCours = Color(0xFFE07B3A);
  static const Color statusResolu = Color(0xFF2D9B6B);

  // Nav bar
  static const Color navBar = Color(0xFF1A4731);
  static const Color navActive = Color(0xFFE07B3A);
  static const Color navInactive = Color(0xFF6B9E84);
}

class AppTextStyles {
  static const String fontFamily = 'Outfit';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle budgetAmount = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.1,
  );
}

class AppDimens {
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;

  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 100;

  static const double cardElevation = 0;
  static const double navBarHeight = 68;
  static const double appBarHeight = 56;
}

class AppStrings {
  // Onboarding
  static const String onboarding1Title = 'La Transparence\nTotale';
  static const String onboarding1Body =
      'Suivez chaque franc dépensé par votre commune en temps réel. Des écoles aux routes, tout est à votre portée.';

  static const String onboarding2Title = 'La Confiance';
  static const String onboarding2Body =
      'Vos données sont protégées par une technologie performante et sont non modifiables.';

  static const String onboarding3Title = 'Votre Voix Compte';
  static const String onboarding3Body =
      'Scannez les chantiers QR pour voir le budget en temps réel. Accédez aux données blockchain de votre commune.';

  // Auth
  static const String createAccount = 'Créer un compte';
  static const String loginTitle = 'Heureux de vous revoir';
  static const String loginSubtitle =
      'Veuillez entrer vos identifiants pour accéder à votre espace citoyen.';
  static const String verifyTitle = 'Vérification de\nsécurité';

  // Nav
  static const String navAccueil = 'Accueil';
  static const String navCommunes = 'Communes';
  static const String navScan = 'Scan';
}
