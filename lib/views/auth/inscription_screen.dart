// lib/views/auth/inscription_screen.dart
// Inscription citoyen : prénom, nom, e-mail, mot de passe (Firebase Auth).
// Paramètre [redirectAfterSignup] : route vers laquelle rediriger après succès.

import 'package:budget_ouvert/controllers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import 'package:provider/provider.dart';

class InscriptionScreen extends StatefulWidget {
  final String? redirectAfterSignup;

  const InscriptionScreen({super.key, this.redirectAfterSignup});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _erreur;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _inscrire() async {
    final nom = _nomController.text.trim();
    final prenom = _prenomController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (nom.isEmpty ||
        prenom.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty) {
      setState(
          () => _erreur = 'Veuillez remplir tous les champs obligatoires.');
      return;
    }

    if (password.length < 6) {
      setState(() =>
          _erreur = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    if (password != confirm) {
      setState(() => _erreur = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      await FirebaseAuthService.signUp(
        prenom: prenom,
        nom: nom,
        email: email,
        password: password,
      );

      // APRÈS
      if (mounted) {
        context.read<AppController>().onAuthChanged();
        if (widget.redirectAfterSignup != null) {
          context.go(widget.redirectAfterSignup!);
        } else {
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
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SvgPicture.asset(
                  'assets/images/logo.svg',
                  colorFilter:
                      const ColorFilter.mode(AppColors.accent, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 20),
              Text(AppStrings.createAccount,
                  style: AppTextStyles.headlineLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Créez votre espace citoyen pour signaler des anomalies.',
                  style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
              if (widget.redirectAfterSignup != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Créez votre compte pour effectuer un signalement.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _Label('Prénom *'),
              const SizedBox(height: 6),
              BudgetTextField(
                controller: _prenomController,
                hint: 'Votre prénom',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _Label('Nom *'),
              const SizedBox(height: 6),
              BudgetTextField(
                controller: _nomController,
                hint: 'Votre nom de famille',
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _Label('E-mail *'),
              const SizedBox(height: 6),
              BudgetTextField(
                controller: _emailController,
                hint: 'vous@exemple.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _Label('Mot de passe *'),
              const SizedBox(height: 6),
              BudgetTextField(
                controller: _passwordController,
                hint: 'Au moins 6 caractères',
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
              const SizedBox(height: 14),
              _Label('Confirmer le mot de passe *'),
              const SizedBox(height: 6),
              BudgetTextField(
                controller: _confirmPasswordController,
                hint: 'Répétez le mot de passe',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
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
                label: "Créer mon compte",
                onPressed: _inscrire,
                isLoading: _loading,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Déjà inscrit ? ", style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      final redirect = widget.redirectAfterSignup;
                      final route = redirect != null
                          ? '/connexion?redirect=${Uri.encodeComponent(redirect)}'
                          : '/connexion';
                      context.go(route);
                    },
                    child: Text(
                      'Se connecter',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
