// lib/views/auth/connexion_screen.dart
// Connexion citoyen : e-mail + mot de passe (Firebase Auth).
// Paramètre [redirectAfterLogin] : route vers laquelle rediriger après succès.

import 'package:budget_ouvert/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

import 'package:provider/provider.dart';

class ConnexionScreen extends StatefulWidget {
  final String? redirectAfterLogin;

  const ConnexionScreen({super.key, this.redirectAfterLogin});

  @override
  State<ConnexionScreen> createState() => _ConnexionScreenState();
}

class _ConnexionScreenState extends State<ConnexionScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _erreur = 'Veuillez remplir tous les champs.');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      await FirebaseAuthService.signIn(
        email: email,
        password: password,
      );

      // APRÈS
      if (mounted) {
        context.read<AppController>().onAuthChanged();
        if (widget.redirectAfterLogin != null) {
          // Vient d'un redirect (ex: signalement) → push pour garder la pile

          context.pushReplacement(widget.redirectAfterLogin!);
        } else {
          // Connexion normale → remplace tout vers accueil
          context.go('/accueil');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erreur = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  colorFilter:
                      const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BudgetOuvert',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 36),
              Text(AppStrings.loginTitle,
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(AppStrings.loginSubtitle,
                  style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              if (widget.redirectAfterLogin != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connectez-vous pour effectuer un signalement.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('E-mail',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 8),
              BudgetTextField(
                controller: _emailController,
                hint: 'vous@exemple.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Mot de passe',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              const SizedBox(height: 8),
              BudgetTextField(
                controller: _passwordController,
                hint: '••••••••',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_erreur!,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: 'Se connecter',
                onPressed: _connecter,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Pas encore de compte ? ",
                      style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      final redirect = widget.redirectAfterLogin;
                      final route = redirect != null
                          ? '/inscription?redirect=${Uri.encodeComponent(redirect)}'
                          : '/inscription';
                      context.push(route);
                    },
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
              const SizedBox(height: 40),
              Text('ASSISTANCE AUDIO',
                  style: AppTextStyles.caption.copyWith(
                      letterSpacing: 1.5, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
