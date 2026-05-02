// lib/views/project/project_detail_screen.dart
import 'package:flutter/material.dart';

import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/audio_player_card.dart';
import '../../widgets/commune_map_widget.dart';
import '../../models/commune_model.dart';
import 'package:latlong2/latlong.dart';

class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final project = ProjectModel.samples()
        .firstWhere((p) => p.id == projectId, orElse: () => ProjectModel.samples().first);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BudgetAppBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header card
          _ProjectHeaderCard(project: project),

          // Audio section
          if (project.audios.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.hearing, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Écouter le projet',
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: project.audios.map((a) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AudioPlayerCard(
                      langue: a.langue,
                      audioUrl: a.url,
                      isAsset: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Cette fonctionnalité permet à tous les citoyens d\'écouter les informations du projet dans leur langue maternelle.',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          ],

          // Funding card
          _FundingCard(project: project),

          // Progress card
          _ProgressCard(project: project),

          // Location card
          _LocationCard(project: project),

          // Timeline
          _TimelineCard(project: project),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProjectHeaderCard extends StatelessWidget {
  final ProjectModel project;
  const _ProjectHeaderCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusChip(
                label: project.statut == 'livré' ? 'Livré' : 'En cours',
                statut: project.statut,
              ),
              const SizedBox(width: 10),
              Text(
                project.code,
                style: AppTextStyles.caption.copyWith(color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.titre,
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.white,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            project.description,
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _FundingCard extends StatelessWidget {
  final ProjectModel project;
  const _FundingCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FINANCEMENT',
            style: AppTextStyles.caption.copyWith(
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatAmount(project.financement)}M FCFA',
            style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 4),
          Text('Budget Total Approuvé', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: project.financement > 0
                  ? project.investissementPaye / project.financement
                  : 0,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.success),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              project.financement > 0
                  ? '${((project.investissementPaye / project.financement) * 100).toInt()}%'
                  : '0%',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) => (amount / 1000000).toStringAsFixed(0);
}

class _ProgressCard extends StatelessWidget {
  final ProjectModel project;
  const _ProgressCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progression\nGlobale', style: AppTextStyles.titleLarge),
              Text(
                '${project.progressionGlobale.toInt()}%',
                style: AppTextStyles.displayLarge.copyWith(fontSize: 36),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (project.statut == 'livré') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.statusLivre.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.statusLivre),
                  const SizedBox(width: 8),
                  Text(
                    'Projet complété avec succès',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.statusLivre),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          ...project.etapes.map((e) {
            return _EtapeRow(etape: e);
          }).toList(),
        ],
      ),
    );
  }
}

class _EtapeRow extends StatelessWidget {
  final EtapeModel etape;
  const _EtapeRow({required this.etape});

  @override
  Widget build(BuildContext context) {
    final isDone = etape.statut == 'terminé';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etape.label, style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                )),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: isDone ? 1.0 : 0.5,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation(
                    isDone ? AppColors.success : AppColors.accent,
                  ),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusChip(
            label: isDone ? 'Terminé' : etape.statut,
            statut: isDone ? 'livré' : 'en_cours',
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final ProjectModel project;
  const _LocationCard({required this.project});

  // Coordonnées par projet (à remplacer par vraies coords depuis l'API)
  static const Map<String, LatLng> _coords = {
    'proj001': LatLng(5.3612, -4.0071),
    'proj002': LatLng(5.3588, -4.0102),
    'proj003': LatLng(5.3625, -4.0055),
    'proj004': LatLng(5.3570, -4.0120),
  };

  @override
  Widget build(BuildContext context) {
    final coordinates = _coords[project.id] ?? const LatLng(5.3600, -4.0083);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Localisation', style: AppTextStyles.titleLarge.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          Text(project.localisation, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),

          // ── Vraie carte interactive ──────────────────────────────────
          ProjectLocationMap(
            localisation: project.localisation,
            coordinates: coordinates,
            height: 160,
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  final ProjectModel project;
  const _TimelineCard({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Chronologie', style: AppTextStyles.titleLarge.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),

          _TimelineItem(
            date: project.dateDebut,
            label: 'Lancement des travaux',
            isDone: true,
            isFirst: true,
          ),
          _TimelineItem(
            date: project.dateFin,
            label: 'Livraison d\'ouverture',
            isDone: project.statut == 'livré',
            isFirst: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String date;
  final String label;
  final bool isDone;
  final bool isFirst;

  const _TimelineItem({
    required this.date,
    required this.label,
    required this.isDone,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.success : AppColors.divider,
                  border: Border.all(
                    color: isDone ? AppColors.success : AppColors.divider,
                    width: 2,
                  ),
                ),
              ),
              if (!isFirst)
                const SizedBox.shrink()
              else
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(label, style: AppTextStyles.bodyMedium),
              if (isFirst) const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.1)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
