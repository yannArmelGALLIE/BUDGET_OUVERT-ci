// lib/views/auth/inscription_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  String _selectedCommune = '';
  bool _loading = false;
  String _selectedLangue = 'Baoulé';

  final List<String> _communes = [
    'Adjamé',
    'Abobo',
    'Attécoubé',
    'Cocody',
    'Koumassi',
    'Marcory',
    'Plateau',
    'Port-Bouët',
    'Treichville',
    'Yopougon',
  ];

  final List<String> _langues = ['Baoulé', 'Dioula', 'Bété'];

  Future<void> _submit() async {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SizedBox(
                  child: SvgPicture.asset(
                    'assets/images/logo.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.accent,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                AppStrings.createAccount,
                style: AppTextStyles.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Remplissez les informations ci-dessous pour accéder au portail.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Name row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Nom'),
                        const SizedBox(height: 6),
                        BudgetTextField(hint: 'ex: Kouadio'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Prénom'),
                        const SizedBox(height: 6),
                        BudgetTextField(hint: 'ex: Jean'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Phone
              _FieldLabel('Numéro de téléphone'),
              const SizedBox(height: 6),
              BudgetTextField(
                hint: '+225 00 00 00 00 00',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // CNI
              _FieldLabel('Numéro de CNI'),
              const SizedBox(height: 6),
              BudgetTextField(
                hint: 'CI0000000000',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.text,
              ),

              // Privacy note
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Utilisé uniquement pour valider votre identité',
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),

              // Commune
              _FieldLabel('Commune'),
              const SizedBox(height: 6),
              _CommuneDropdown(
                communes: _communes,
                selected: _selectedCommune,
                onChanged: (v) => setState(() => _selectedCommune = v ?? ''),
              ),
              const SizedBox(height: 28),

              // Submit button
              PrimaryButton(
                label: 'Créer mon compte',
                onPressed: _submit,
                isLoading: _loading,
              ),
              const SizedBox(height: 20),

              // Already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Déjà un compte ? ', style: AppTextStyles.bodyMedium),
                  GestureDetector(
                    onTap: () => context.go('/connexion'),
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
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),

              // Language preference
              Text(
                'Langue préférée pour l\'audio :',
                style:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _langues.map((l) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LangueChip(
                      label: l,
                      selected: _selectedLangue == l,
                      onTap: () => setState(() => _selectedLangue = l),
                    ),
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        fontSize: 13,
      ),
    );
  }
}

class _CommuneDropdown extends StatelessWidget {
  final List<String> communes;
  final String selected;
  final ValueChanged<String?> onChanged;

  const _CommuneDropdown({
    required this.communes,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected.isEmpty ? null : selected,
          hint: Text(
            'Sélectionnez votre commune',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textHint),
          ),
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.textSecondary),
          items: communes
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
        ),
      ),
    );
  }
}
