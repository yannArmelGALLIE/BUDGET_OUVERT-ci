// lib/views/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'La Transparence\nTotale',
      body:
          'Suivez chaque franc dépensé par votre commune en temps réel. Des écoles aux routes, tout est à votre portée.',
      icon: Icons.receipt_long_outlined,
      illustrationKey: 'transparency',
    ),
    _OnboardingPage(
      title: 'La Confiance',
      body:
          'Vos données sont protégées par une technologie performante et sont non modifiables.',
      icon: Icons.verified_user_outlined,
      illustrationKey: 'trust',
    ),
    _OnboardingPage(
      title: 'Votre Voix\nCompte',
      body:
          'Scannez les chantiers pour voir les budgets ou signalez un problème en un clic. Devenez acteur de votre commune.',
      icon: Icons.qr_code_scanner,
      illustrationKey: 'action',
      isLast: true,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/connexion');
    }
  }

  void _skip() => context.go('/connexion');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  'Passer',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _OnboardingPageWidget(page: _pages[i]),
              ),
            ),

            // Indicator & button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      activeDotColor: AppColors.primary,
                      dotColor: AppColors.divider,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final String title;
  final String body;
  final IconData icon;
  final String illustrationKey;
  final bool isLast;

  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
    required this.illustrationKey,
    this.isLast = false,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;

  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Illustration card
          Expanded(
            child: _IllustrationCard(page: page),
          ),

          const SizedBox(height: 32),

          // Text content
          Text(
            page.title,
            style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            page.body,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final _OnboardingPage page;

  const _IllustrationCard({required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
      ),
      child: page.illustrationKey == 'action'
          ? _ActionIllustration()
          : page.illustrationKey == 'trust'
              ? _TrustIllustration()
              : _TransparencyIllustration(),
    );
  }
}

// ─── ILLUSTRATIONS ─────────────────────────────────────────────────────────

class _TransparencyIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Budget card mockup
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_outlined,
                          size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 80, height: 8, color: AppColors.primary.withOpacity(0.2),
                            margin: const EdgeInsets.only(bottom: 4)),
                        Container(width: 50, height: 6, color: AppColors.divider),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                    width: double.infinity, height: 8, color: AppColors.divider,
                    margin: const EdgeInsets.only(bottom: 6)),
                Container(
                    width: 160, height: 8, color: AppColors.divider,
                    margin: const EdgeInsets.only(bottom: 12)),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Floating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 16, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  '70% exécuté',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 3 shield icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ShieldIcon(label: 'ÉCHANGÉ', icon: Icons.swap_horiz),
              const SizedBox(width: 12),
              _ShieldIcon(label: 'CONSENSUS', icon: Icons.verified, highlighted: true),
              const SizedBox(width: 12),
              _ShieldIcon(label: 'ROUTÉ', icon: Icons.route),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: Text(
              'Données sécurisées & immuables',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShieldIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;

  const _ShieldIcon({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: highlighted ? AppColors.primary : AppColors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 28,
            color: highlighted ? AppColors.white : AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _ActionIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Phone with QR code mockup
          Container(
            width: 160,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 60, color: AppColors.white),
                const SizedBox(height: 10),
                Text(
                  'Scanner le QR',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Budget badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet, size: 14, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  'Solde disponible: 40.000.000 FCFA',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FeatureBadge(icon: Icons.qr_code, label: 'Scan QR'),
              const SizedBox(width: 12),
              _FeatureBadge(
                icon: Icons.flag,
                label: 'Signalement',
                highlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _FeatureBadge({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accent.withOpacity(0.15) : AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: highlighted ? AppColors.accent : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14,
              color: highlighted ? AppColors.accent : AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: highlighted ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
