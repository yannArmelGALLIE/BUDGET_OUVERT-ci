// lib/views/signalement/signalement_screen.dart
// Formulaire de signalement d'une transaction suspecte.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/signalement_model.dart';
import '../../models/transaction_model.dart';
import '../../models/citoyen_model.dart';
import '../../services/blockchain_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class SignalementScreen extends StatefulWidget {
  final String transactionId;

  const SignalementScreen({super.key, required this.transactionId});

  @override
  State<SignalementScreen> createState() => _SignalementScreenState();
}

class _SignalementScreenState extends State<SignalementScreen> {
  // ── État ────────────────────────────────────────────────────────────────
  final _commentaireController = TextEditingController();
  TypeSignalement _typeSelectionne = TypeSignalement.erreur;
  final List<File> _preuves = [];
  bool _loading = false;
  bool _loadingTx = true;
  TransactionModel? _transaction;

  CitoyenModel? get _citoyenEffectif => FirebaseAuthService.currentCitoyen;

  @override
  void initState() {
    super.initState();
    _chargerTransaction();
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _chargerTransaction() async {
    try {
      final tx =
          await BlockchainService.getTransactionById(widget.transactionId);
      if (mounted) {
        setState(() {
          _transaction = tx;
          _loadingTx = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingTx = false);
    }
  }

  bool _peutSoumettre() {
    if (FirebaseAuthService.isLoggedIn) return true;
    final redirect =
        Uri.encodeComponent('/signalement/\${widget.transactionId}');
    context.push('/connexion?redirect=\$redirect');
    return false;
  }

  // ── Actions ─────────────────────────────────────────────────────────────
  Future<void> _ajouterPreuve() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Ajouter une preuve', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_camera_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Photo / Vidéo'),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.camera, imageQuality: 70);
                if (img != null && mounted) {
                  setState(() => _preuves.add(File(img.path)));
                }
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Galerie'),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 70);
                if (img != null && mounted) {
                  setState(() => _preuves.add(File(img.path)));
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _soumettre() async {
    if (!_peutSoumettre()) return;

    if (_commentaireController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez décrire le problème observé.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirestoreService.creerSignalement(
        transactionId: widget.transactionId,
        type: _typeSelectionne,
        commentaire: _commentaireController.text.trim(),
        preuves: _preuves,
      );

      if (mounted) {
        _afficherSucces();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  void _afficherSucces() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXL)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  size: 32, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            Text('Signalement envoyé',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Votre signalement a été transmis. Vous pouvez suivre son évolution dans "Mes signalements".',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Voir mes signalements',
              onPressed: () {
                Navigator.of(context).pop();

                context.pushReplacement('/mes-signalements');
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop();
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Signaler une transaction',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loadingTx
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Résumé de la transaction ────────────────────────
                  if (_transaction != null) _ResumeTx(tx: _transaction!),
                  const SizedBox(height: 20),

                  // ── Citoyen connecté (ou fictif en mode test) ───────
                  _CitoyenBadge(citoyen: _citoyenEffectif),
                  const SizedBox(height: 20),

                  // ── Type de signalement ─────────────────────────────
                  _SectionLabel(label: 'Type de problème'),
                  const SizedBox(height: 10),
                  _TypeSelector(
                    selected: _typeSelectionne,
                    onChanged: (t) => setState(() => _typeSelectionne = t),
                  ),
                  const SizedBox(height: 20),

                  // ── Commentaire ─────────────────────────────────────
                  _SectionLabel(label: 'Description du problème'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: TextField(
                      controller: _commentaireController,
                      maxLines: 5,
                      style: AppTextStyles.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Décrivez précisément l\'anomalie observée…',
                        hintStyle: AppTextStyles.bodyMedium,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.all(AppDimens.paddingM),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Preuves ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionLabel(label: 'Preuves (optionnel)'),
                      TextButton.icon(
                        onPressed: _ajouterPreuve,
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            size: 16),
                        label: const Text('Ajouter'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  if (_preuves.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _PreuvesGrid(
                        preuves: _preuves,
                        onSupprimer: (i) {
                          setState(() => _preuves.removeAt(i));
                        }),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cloud_upload_outlined,
                              color: AppColors.textHint, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Aucune preuve jointe',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // ── Bouton soumettre ─────────────────────────────────
                  PrimaryButton(
                    label: 'Soumettre le signalement',
                    onPressed: _soumettre,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 12),

                  // ── Note légale ──────────────────────────────────────
                  Text(
                    'Les faux signalements peuvent entraîner la suspension de votre compte.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ─── WIDGETS INTERNES ─────────────────────────────────────────────────────────

class _ResumeTx extends StatelessWidget {
  final TransactionModel tx;
  const _ResumeTx({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isRev = tx.isRevenue ?? false;
    final color = isRev ? AppColors.success : AppColors.accent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isRev ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.libelle,
                    style: AppTextStyles.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${isRev ? '+' : '-'} ${tx.amountFormatted} FCFA',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CitoyenBadge extends StatelessWidget {
  final CitoyenModel? citoyen;
  const _CitoyenBadge({this.citoyen});

  @override
  Widget build(BuildContext context) {
    if (citoyen == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Connecté en tant que \${citoyen!.nomComplet}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final TypeSignalement selected;
  final ValueChanged<TypeSignalement> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = [
      (TypeSignalement.erreur, 'Erreur', Icons.error_outline_rounded),
      (TypeSignalement.fraude, 'Fraude', Icons.warning_amber_rounded),
      (TypeSignalement.doublon, 'Doublon', Icons.copy_rounded),
      (TypeSignalement.autre, 'Autre', Icons.more_horiz_rounded),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: types.map((t) {
        final isSelected = selected == t.$1;
        return GestureDetector(
          onTap: () => onChanged(t.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$3,
                    size: 16,
                    color:
                        isSelected ? AppColors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  t.$2,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: isSelected ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PreuvesGrid extends StatelessWidget {
  final List<File> preuves;
  final ValueChanged<int> onSupprimer;

  const _PreuvesGrid({required this.preuves, required this.onSupprimer});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: preuves.asMap().entries.map((e) {
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              child: Image.file(
                e.value,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onSupprimer(e.key),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 12, color: AppColors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.titleLarge);
  }
}
