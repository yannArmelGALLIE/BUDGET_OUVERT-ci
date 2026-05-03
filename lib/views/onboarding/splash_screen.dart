// lib/views/onboarding/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
// Imports ajoutés en haut
import 'package:provider/provider.dart';
import '../../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _subtitleOpacity;

// Nouvelle méthode ajoutée avant dispose()
  Future<void> _navigateAfterSplash() async {
    // Attendre la durée totale du splash (animation 2s + pause 1s)
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final session = context.read<SessionService>();

    if (!session.hasSeenOnboarding) {
      // Première ouverture : montrer l'onboarding
      context.go('/onboarding');
    } else if (session.isLoggedIn) {
      // Déjà connecté : aller directement à l'accueil
      context.go('/accueil');
    } else {
      // Onboarding vu mais pas connecté : aller à la connexion
      context.go('/connexion');
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    _navigateAfterSplash();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background circles
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryDark.withOpacity(0.4),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo circle
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _ElephantIcon(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Opacity(
                    opacity: _textOpacity.value,
                    child: const Text(
                      'BUDGETOUVERT',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Opacity(
                    opacity: _subtitleOpacity.value,
                    child: const Text(
                      'TRANSPARENCE CITOYENNE',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white60,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom badge
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Opacity(
                opacity: _subtitleOpacity.value,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag, size: 14, color: Colors.white60),
                        const SizedBox(width: 6),
                        const Text(
                          'RÉPUBLIQUE DE CÔTE D\'IVOIRE',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            color: Colors.white60,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'MINISTÈRE DU BUDGET ET DU PORTEFEUILLE DE L\'ÉTAT',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 8,
                        color: Colors.white38,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ElephantIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        colorFilter: const ColorFilter.mode(
          AppColors.accent,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
