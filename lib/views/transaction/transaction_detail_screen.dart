// lib/views/transaction/transaction_detail_screen.dart
// Page détail d'une transaction.
// Contenu : montant, description, date, justificatif, audio explicatif,
//           hash blockchain, bouton "Signaler".
// Le bouton "Signaler" vérifie la session → redirige vers connexion si besoin.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/transaction_model.dart';
import '../../services/blockchain_service.dart';
import '../../services/firebase_auth_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/audio_player_card.dart';


class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _transaction;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chargerTransaction();
  }

  Future<void> _chargerTransaction() async {
    try {
      final tx = await BlockchainService.getTransactionById(widget.transactionId);
      if (mounted) {
        setState(() {
          _transaction = tx;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger la transaction.';
          _loading = false;
        });
      }
    }
  }

  // ── Gestion du bouton Signaler ──────────────────────────────────────────
  void _onSignalerPressed() {
    if (FirebaseAuthService.isLoggedIn) {
      context.push('/signalement/${widget.transactionId}');
    } else {
      // Redirige vers connexion avec paramètre de retour
      final redirect =
          Uri.encodeComponent('/signalement/${widget.transactionId}');
      context.push('/connexion?redirect=$redirect');
    }
  }

  Future<void> _ouvrirJustificatif(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          'Détail transaction',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _chargerTransaction)
              : _transaction == null
                  ? const _ErrorView(message: 'Transaction introuvable.')
                  : _Body(
                      transaction: _transaction!,
                      onSignaler: _onSignalerPressed,
                      onOuvrirJustificatif: _ouvrirJustificatif,
                    ),
    );
  }
}

// ─── CORPS PRINCIPAL ──────────────────────────────────────────────────────
class _Body extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onSignaler;
  final Future<void> Function(String) onOuvrirJustificatif;

  const _Body({
    required this.transaction,
    required this.onSignaler,
    required this.onOuvrirJustificatif,
  });

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final isRev = tx.isRevenue;
    final color = isRev ?? false ? AppColors.success : AppColors.accent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Carte hero montant ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isRev ?? false
                    ? [const Color(0xFF1E6B45), const Color(0xFF2D9B6B)]
                    : [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppDimens.radiusXL),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        isRev ?? false ? 'RECETTE' : 'DÉPENSE',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${isRev ?? false ? '+' : '-'} ${tx.amountFormatted} FCFA',
                  style: AppTextStyles.budgetAmount,
                ),
                const SizedBox(height: 6),
                Text(
                  tx.libelle,
                  style:
                      AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Informations générales ────────────────────────────────────
          _SectionCard(
            title: 'Informations',
            child: Column(
              children: [
                _InfoRow(label: 'Catégorie', value: tx.category),
                _InfoRow(
                  label: 'Date',
                  value:
                      '${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}',
                ),
                if (tx.reference != null)
                  _InfoRow(label: 'Référence', value: tx.reference!),
                _InfoRow(label: 'Statut', value: tx.statut),
                if (tx.dateValidation != null)
                  _InfoRow(
                    label: 'Validé le',
                    value:
                        '${tx.dateValidation!.day.toString().padLeft(2, '0')}/${tx.dateValidation!.month.toString().padLeft(2, '0')}/${tx.dateValidation!.year}',
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Description ───────────────────────────────────────────────
          _SectionCard(
            title: 'Description',
            child: Text(
              tx.description,
              style: AppTextStyles.bodyLarge,
            ),
          ),

          // ── Justificatif ──────────────────────────────────────────────
          if (tx.hasJustificatif) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Pièce justificative',
              child: GestureDetector(
                onTap: () => onOuvrirJustificatif(tx.pieceJustificativeUrl!),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voir le justificatif',
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.primary),
                          ),
                          Text(
                            'Facture / bon de commande',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Audio explicatif ──────────────────────────────────────────
          if (tx.hasAudio) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title:
                  'Audio explicatif${tx.audioLangue != null ? ' · ${tx.audioLangue}' : ''}',
              child: AudioPlayerCard(langue: "", audioUrl: tx.audioUrl!),
            ),
          ],

          const SizedBox(height: 28),

          // ── Bouton Signaler ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSignaler,
              icon: const Icon(Icons.flag_rounded, size: 18),
              label: const Text('Signaler cette transaction'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                textStyle: AppTextStyles.labelLarge,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Note transparence ─────────────────────────────────────────
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
                    'Les signalements sont traités par la Cour des Comptes et les administrateurs communaux. NB: Vous devez être connecté pour signaler une transaction.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── WIDGETS INTERNES ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message,
                style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ]
          ],
        ),
      ),
    );
  }
}
