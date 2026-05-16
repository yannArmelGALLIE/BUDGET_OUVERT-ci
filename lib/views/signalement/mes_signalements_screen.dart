// lib/views/signalement/mes_signalements_screen.dart
// Liste des signalements soumis par le citoyen connecté.
// Chaque item affiche le type, statut, date et commentaire.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/signalement_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';

class MesSignalementsScreen extends StatefulWidget {
  const MesSignalementsScreen({super.key});

  @override
  State<MesSignalementsScreen> createState() => _MesSignalementsScreenState();
}

class _MesSignalementsScreenState extends State<MesSignalementsScreen> {
  List<SignalementModel> _signalements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final data = await FirestoreService.mesSignalements();
      if (mounted)
        setState(() {
          _signalements = data;
          _loading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur : $e';
          _loading = false;
        });
      }
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
          'Mes signalements',
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
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: AppTextStyles.bodyLarge),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _charger();
                          },
                          child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _signalements.isEmpty
                  ? _EmptyState()
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppDimens.paddingM),
                        itemCount: _signalements.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) =>
                            _SignalementCard(s: _signalements[i]),
                      ),
                    ),
    );
  }
}

// ─── CARTE SIGNALEMENT ────────────────────────────────────────────────────
class _SignalementCard extends StatelessWidget {
  final SignalementModel s;
  const _SignalementCard({required this.s});

  Color get _statutColor {
    switch (s.statut) {
      case StatutSignalement.ouvert:
        return AppColors.info;
      case StatutSignalement.enCours:
        return AppColors.warning;
      case StatutSignalement.resolu:
        return AppColors.success;
      case StatutSignalement.rejete:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // ── En-tête ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                child: Text(
                  s.statutLabel.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: _statutColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                s.typeLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Commentaire ──────────────────────────────────────────────
          Text(
            s.commentaire,
            style: AppTextStyles.bodyLarge,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ── Date + preuves ────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                '${s.dateSignalement.day.toString().padLeft(2, '0')}/'
                '${s.dateSignalement.month.toString().padLeft(2, '0')}/'
                '${s.dateSignalement.year}',
                style: AppTextStyles.caption,
              ),
              if (s.preuves.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.attach_file_rounded,
                    size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${s.preuves.length} preuve(s)',
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── ÉTAT VIDE ────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.flag_outlined,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucun signalement',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore signalé de transaction. '
              'Si vous observez une anomalie, utilisez le bouton "Signaler" '
              'sur la page de détail d\'une transaction.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
