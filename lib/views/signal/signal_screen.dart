// lib/views/signal/signal_screen.dart
import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/signal_model.dart';

class SignalScreen extends StatefulWidget {
  const SignalScreen({super.key});

  @override
  State<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends State<SignalScreen> {
  String _selectedType = '';
  bool _isSubmitting = false;
  bool _submitted = false;
  final List<SignalModel> _mySignals = SignalModel.samples();

  final List<_TypeOption> _types = [
    _TypeOption(label: 'Voirie', icon: Icons.aod),
    const _TypeOption(label: 'Éclairage Public', icon: Icons.lightbulb_outline),
    const _TypeOption(label: 'Assainissement', icon: Icons.water_drop_outlined),
    const _TypeOption(label: 'Déchets', icon: Icons.delete_outline),
    const _TypeOption(label: 'Autres', icon: Icons.more_horiz),
  ];

  Future<void> _submit() async {
    if (_selectedType.isEmpty) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _submitted = true;
        _mySignals.insert(
          0,
          SignalModel(
            id: 'new',
            type: _selectedType,
            localisation: 'Abidjan, Cocody Riviera 3',
            description: 'Nouveau signalement',
            statut: 'nouveau',
            date: 'Aujourd\'hui',
          ),
        );
      });

      // Reset after showing success
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _submitted = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BudgetAppBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Signal form card
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Text('Signaler un Problème',
                      style: AppTextStyles.headlineMedium),
                ),
                const Divider(height: 1, color: AppColors.divider),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo upload
                      _PhotoUploadBox(),
                      const SizedBox(height: 20),

                      // Type section
                      Row(
                        children: [
                          const Icon(Icons.category_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Type de Problème',
                              style: AppTextStyles.titleLarge.copyWith(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _types.map((t) {
                          final isSelected = _selectedType == t.label;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedType = t.label),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.inputBg,
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusFull),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                t.label,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isSelected
                                      ? AppColors.white
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Localisation',
                              style: AppTextStyles.titleLarge.copyWith(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.my_location,
                                  size: 16, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Abidjan, Cocody Riviera 3',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600)),
                                Text('Position détectée via GPS',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text('Description',
                          style: AppTextStyles.titleLarge.copyWith(fontSize: 14)),
                      const SizedBox(height: 8),
                      Container(
                        height: 90,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        ),
                        child: TextField(
                          maxLines: null,
                          decoration: InputDecoration.collapsed(
                            hintText: 'Décrivez brièvement le problème...',
                            hintStyle: AppTextStyles.bodyMedium,
                          ),
                          style: AppTextStyles.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit
                      if (_submitted)
                        _SuccessBanner()
                      else
                        PrimaryButton(
                          label: 'Envoyer le Signalement',
                          onPressed: _selectedType.isEmpty ? null : _submit,
                          isLoading: _isSubmitting,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // My signals
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SectionHeader(
              title: 'Mes Signalements',
              actionLabel: 'Voir tout',
              onAction: () {},
            ),
          ),
          ..._mySignals.map((s) => _SignalTile(signal: s)).toList(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TypeOption {
  final String label;
  final IconData icon;
  const _TypeOption({required this.label, required this.icon});
}

class _PhotoUploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                size: 24, color: AppColors.textSecondary),
            const SizedBox(height: 6),
            Text(
              'Ajouter une photo du problème',
              style: AppTextStyles.bodyMedium,
            ),
            Text(
              'Prenez une photo claire pour une intervention rapide',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.statusLivre.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: AppColors.statusLivre.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.statusLivre, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Signalement envoyé avec succès ! Nos équipes vont traiter votre demande.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusLivre),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalTile extends StatelessWidget {
  final SignalModel signal;
  const _SignalTile({required this.signal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_outlined, size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeToLabel(signal.type),
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 13),
                ),
                Text(signal.localisation, style: AppTextStyles.caption),
                Text(signal.date, style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusChip(
            label: signal.statut == 'en_cours' ? 'EN COURS' : 'RÉSOLU',
            statut: signal.statut == 'en_cours' ? 'en_cours' : 'livré',
          ),
        ],
      ),
    );
  }

  String _typeToLabel(String type) {
    switch (type) {
      case 'eclairage': return 'Éclairage défaillant';
      case 'voirie': return 'Nid de poule';
      default: return 'Signalement - $type';
    }
  }
}
