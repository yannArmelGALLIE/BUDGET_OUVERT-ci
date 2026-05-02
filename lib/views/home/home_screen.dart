// lib/views/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/commune_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final commune = CommuneModel.sample();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BudgetAppBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Budget hero card
          _BudgetHeroCard(commune: commune),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _QuickAction(
                  icon: Icons.search,
                  label: 'Rechercher\nCommune',
                  onTap: () => context.go('/communes'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.grid_view,
                  label: 'Carte\nProjets',
                  onTap: () => context.go('/communes'),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.notifications_outlined,
                  label: 'Alertes',
                  badge: true,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Info en bref
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionHeader(
              title: 'Info en bref',
              actionLabel: 'Voir tout',
              onAction: () {},
            ),
          ),
          _InfoCard(commune: commune),

          // Projets en cours
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: SectionHeader(title: 'Projets en cours'),
          ),
          _ProjectsRow(projets: commune.projets),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── BUDGET HERO ───────────────────────────────────────────────────────────
class _BudgetHeroCard extends StatelessWidget {
  final CommuneModel commune;

  const _BudgetHeroCard({required this.commune});

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
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        'BUDGET CITOYEN',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.photo_camera_outlined,
                        color: Colors.white54, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Solde Disponible',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatAmount(commune.budgetTotal)} FCFA',
                  style: AppTextStyles.budgetAmount,
                ),
                const SizedBox(height: 16),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: commune.tauxExecution / 100,
                    backgroundColor: AppColors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consommation du budget',
                      style: AppTextStyles.caption.copyWith(color: Colors.white70),
                    ),
                    Text(
                      '${commune.tauxExecution.toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final parts = amount.toInt().toString().split('');
    final result = <String>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.add('.');
      result.add(parts[i]);
    }
    return result.join();
  }
}

// ─── QUICK ACTION ──────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool badge;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            children: [
              Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: AppColors.primary),
                  ),
                  if (badge)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── INFO CARD ─────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final CommuneModel commune;

  const _InfoCard({required this.commune});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.radiusL)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: AppColors.primarySurface,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.account_balance, size: 36, color: AppColors.primary),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'INFRASTRUCTURES',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le Pont Alassane Ouattara : Un pilier pour la mobilité urbaine à Abidjan',
                  style: AppTextStyles.titleLarge.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatBadge(
                      icon: Icons.trending_up,
                      label: 'Croissance du budget : +15% de mois en mois',
                    ),
                    const SizedBox(width: 8),
                    _StatBadge(
                      icon: Icons.check_circle_outline,
                      label: '68% des projets de terminés',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label, style: AppTextStyles.caption, maxLines: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROJECTS ROW ──────────────────────────────────────────────────────────
class _ProjectsRow extends StatelessWidget {
  final List<ProjectModel> projets;

  const _ProjectsRow({required this.projets});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: projets.length,
        itemBuilder: (context, i) {
          final p = projets[i];
          return GestureDetector(
            onTap: () => context.go('/projet/${p.id}'),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(14),
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
                  StatusChip(
                    label: _statutLabel(p.statut),
                    statut: p.statut,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.categorie.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.titre,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  LinearProgressIndicator(
                    value: p.progressionGlobale / 100,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      p.statut == 'livré' ? AppColors.success : AppColors.accent,
                    ),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${p.progressionGlobale.toInt()}%',
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _statutLabel(String s) {
    switch (s) {
      case 'livré': return 'Livré';
      case 'en_cours': return 'En cours';
      default: return 'Planifié';
    }
  }
}
