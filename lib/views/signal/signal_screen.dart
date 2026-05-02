// lib/views/signal/signal_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../services/media_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/signal_model.dart';

class SignalScreen extends StatefulWidget {
  const SignalScreen({super.key});

  @override
  State<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends State<SignalScreen> {
  File? _pickedImage;
  final TextEditingController _descriptionCtrl = TextEditingController();

  final List<_TypeOption> _types = const [
    _TypeOption(label: 'Voirie', icon: Icons.aod),
    _TypeOption(label: 'Éclairage Public', icon: Icons.lightbulb_outline),
    _TypeOption(label: 'Assainissement', icon: Icons.water_drop_outlined),
    _TypeOption(label: 'Déchets', icon: Icons.delete_outline),
    _TypeOption(label: 'Autres', icon: Icons.more_horiz),
  ];

  @override
  void initState() {
    super.initState();
    // Charger position GPS + signalements au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<SignalController>();
      ctrl.fetchCurrentLocation();
      ctrl.loadMySignals();
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(SignalController ctrl) async {
    if (ctrl.selectedType.isEmpty) return;
    ctrl.setDescription(_descriptionCtrl.text);
    final ok = await ctrl.submitSignal(photo: _pickedImage);

    if (ok && mounted) {
      _descriptionCtrl.clear();
      setState(() => _pickedImage = null);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) ctrl.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SignalController>(
      builder: (context, ctrl, _) {
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
                          _PhotoUploadBox(
                            image: _pickedImage,
                            onTap: () async {
                              final file =
                                  await MediaService.instance.pickImage(context);
                              if (file != null) {
                                setState(() => _pickedImage = file);
                              }
                            },
                            onRemove: () => setState(() => _pickedImage = null),
                          ),
                          const SizedBox(height: 20),

                          // Type section
                          Row(
                            children: [
                              const Icon(Icons.category_outlined,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Type de Problème',
                                  style: AppTextStyles.titleLarge
                                      .copyWith(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _types.map((t) {
                              final isSelected = ctrl.selectedType == t.label;
                              return GestureDetector(
                                onTap: () => ctrl.setType(t.label),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.inputBg,
                                    borderRadius: BorderRadius.circular(
                                        AppDimens.radiusFull),
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

                          // Localisation (GPS dynamique)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Localisation',
                                  style: AppTextStyles.titleLarge
                                      .copyWith(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: ctrl.isFetchingLocation
                                ? null
                                : () => ctrl.fetchCurrentLocation(),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusM),
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
                                    child: ctrl.isFetchingLocation
                                        ? const Padding(
                                            padding: EdgeInsets.all(6),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.my_location,
                                            size: 16,
                                            color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(ctrl.localisation,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                        Text(
                                            ctrl.isFetchingLocation
                                                ? 'Localisation en cours...'
                                                : 'Appuyer pour actualiser',
                                            style: AppTextStyles.caption),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Description
                          Text('Description',
                              style: AppTextStyles.titleLarge
                                  .copyWith(fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            height: 90,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.radiusM),
                            ),
                            child: TextField(
                              controller: _descriptionCtrl,
                              maxLines: null,
                              decoration: InputDecoration.collapsed(
                                hintText:
                                    'Décrivez brièvement le problème...',
                                hintStyle: AppTextStyles.bodyMedium,
                              ),
                              style: AppTextStyles.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (ctrl.submitted)
                            _SuccessBanner()
                          else
                            PrimaryButton(
                              label: 'Envoyer le Signalement',
                              onPressed: ctrl.selectedType.isEmpty
                                  ? null
                                  : () => _submit(ctrl),
                              isLoading: ctrl.isSubmitting,
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
              ...ctrl.signals
                  .map((s) => _SignalTile(signal: s))
                  .toList(),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _TypeOption {
  final String label;
  final IconData icon;
  const _TypeOption({required this.label, required this.icon});
}

class _PhotoUploadBox extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoUploadBox({
    required this.onTap,
    required this.onRemove,
    this.image,
  });

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            child: Image.file(image!,
                width: double.infinity, height: 160, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child:
                    const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.85),
                  borderRadius:
                      BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text('Modifier',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined,
                size: 26, color: AppColors.textSecondary),
            const SizedBox(height: 6),
            Text('Ajouter une photo du problème',
                style: AppTextStyles.bodyMedium),
            Text('Caméra ou galerie', style: AppTextStyles.caption),
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
        border:
            Border.all(color: AppColors.statusLivre.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.statusLivre, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Signalement envoyé avec succès ! Nos équipes vont traiter votre demande.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.statusLivre),
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
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.flag_outlined,
                size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_typeToLabel(signal.type),
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 13)),
                Text(signal.localisation, style: AppTextStyles.caption),
                Text(signal.date, style: AppTextStyles.caption),
              ],
            ),
          ),
          StatusChip(
            label:
                signal.statut == 'en_cours' ? 'EN COURS' : 'RÉSOLU',
            statut:
                signal.statut == 'en_cours' ? 'en_cours' : 'livré',
          ),
        ],
      ),
    );
  }

  String _typeToLabel(String type) {
    switch (type) {
      case 'eclairage':
        return 'Éclairage défaillant';
      case 'voirie':
        return 'Nid de poule';
      default:
        return 'Signalement - $type';
    }
  }
}
