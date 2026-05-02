// lib/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../views/onboarding/splash_screen.dart';
import '../views/onboarding/onboarding_screen.dart';
import '../views/auth/inscription_screen.dart';
import '../views/auth/connexion_screen.dart';
import '../views/auth/otp_screen.dart';
import '../views/home/home_screen.dart';
import '../views/commune/commune_detail_screen.dart';
import '../views/scan/scan_screen.dart';
import '../views/project/project_detail_screen.dart';
import '../views/signal/signal_screen.dart';
import '../widgets/main_scaffold.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/inscription',
      builder: (context, state) => const InscriptionScreen(),
    ),
    GoRoute(
      path: '/connexion',
      builder: (context, state) => const ConnexionScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) => const OtpScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/accueil',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/communes',
          builder: (context, state) => const CommuneDetailScreen(),
        ),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanScreen(),
        ),
        GoRoute(
          path: '/signal',
          builder: (context, state) => const SignalScreen(),
        ),
        GoRoute(
          path: '/projet/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return ProjectDetailScreen(projectId: id);
          },
        ),
      ],
    ),
  ],
);
