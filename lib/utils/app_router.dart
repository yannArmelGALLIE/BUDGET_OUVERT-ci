// lib/utils/app_router.dart
//
// ShellRoute (MainScaffold — avec bottom nav)
//   ├── /accueil              → HomeScreen
//   ├── /communes             → CommuneSelectionScreen  (onglet "Communes")
//   ├── /commune/:id          → CommuneDetailScreen
//   └── /scan                 → ScanScreen
//
// Routes plein écran (SANS bottom nav)
//   ├── /                     → SplashScreen
//   ├── /onboarding           → OnboardingScreen
//   ├── /transaction/:id      → TransactionDetailScreen
//   ├── /signalement/:txId    → SignalementScreen
//   ├── /mes-signalements     → MesSignalementsScreen
//   ├── /connexion            → ConnexionScreen
//   └── /inscription          → InscriptionScreen
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../views/onboarding/splash_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/commune/commune_selection_screen.dart';
import '../views/commune/commune_detail_screen.dart';
import '../views/home/home_screen.dart';
import '../views/transaction/transaction_detail_screen.dart';
import '../views/signalement/signalement_screen.dart';
import '../views/signalement/mes_signalements_screen.dart';
import '../views/auth/connexion_screen.dart';
import '../views/auth/inscription_screen.dart';
import '../views/scan/scan_screen.dart';
import '../widgets/main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ════════════════════════════════════════════════════════════════════
    // SHELL — écrans avec Bottom Navigation Bar
    // ════════════════════════════════════════════════════════════════════
    ShellRoute(
      builder: (context, state, child) => MainScaffold(
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/accueil',
          pageBuilder: (context, state) =>
              NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/communes',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CommuneSelectionScreen()),
        ),
        GoRoute(
          path: '/commune/:id',
          builder: (context, state) => CommuneDetailScreen(
            communeId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/scan',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ScanScreen()),
        ),
      ],
    ),

    // ════════════════════════════════════════════════════════════════════
    // ROUTES PLEIN ÉCRAN — sans Bottom Navigation Bar
    // ════════════════════════════════════════════════════════════════════
    GoRoute(
      path: '/selection-commune',
      builder: (context, state) => const CommuneSelectionScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/transaction/:id',
      builder: (context, state) => TransactionDetailScreen(
        transactionId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/signalement/:transactionId',
      builder: (context, state) => SignalementScreen(
        transactionId: state.pathParameters['transactionId']!,
      ),
    ),
    GoRoute(
      path: '/mes-signalements',
      builder: (context, state) => const MesSignalementsScreen(),
    ),
    GoRoute(
      path: '/connexion',
      builder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        return ConnexionScreen(redirectAfterLogin: redirect);
      },
    ),
    GoRoute(
      path: '/inscription',
      builder: (context, state) {
        final redirect = state.uri.queryParameters['redirect'];
        return InscriptionScreen(redirectAfterSignup: redirect);
      },
    ),
  ],
);
