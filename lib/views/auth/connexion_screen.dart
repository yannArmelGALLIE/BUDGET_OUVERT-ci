// lib/views/auth/connexion_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class ConnexionScreen extends StatefulWidget {
  const ConnexionScreen({super.key});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  bool _loading = false;

  Future<void> _connect() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _loading = false);
      context.go('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SvgPicture.asset(
    'assets/images/logo.svg',
    colorFilter:const  ColorFilter.mode(
      AppColors.accent,
      BlendMode.srcIn,
    ),
  ),
              ),
              const SizedBox(height: 8),
              Text(
                'BudgetOuvert',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 36),

              // Welcome text
              Text(
                AppStrings.loginTitle,
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                AppStrings.loginSubtitle,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Phone field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Numéro de téléphone',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              BudgetTextField(
                hint: '+225 00 00 00 00 00',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: 'Se connecter',
                onPressed: _connect,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Pas encore de compte ? ", style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () => context.go('/inscription'),
                    child: Text(
                      "S'inscrire",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Assistance audio
              Text(
                'ASSISTANCE AUDIO',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['Baoulé', 'Dioula', 'Senoufo'].map((l) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LangueChip(label: l),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FooterLink('Aide'),
                  const SizedBox(width: 16),
                  _FooterLink('Langues'),
                  const SizedBox(width: 16),
                  _FooterLink('Sécurité'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
