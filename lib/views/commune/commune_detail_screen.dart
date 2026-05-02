// lib/views/commune/commune_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/commune_map_widget.dart';
import '../../models/commune_model.dart';

class CommuneDetailScreen extends StatefulWidget {
  const CommuneDetailScreen({super.key});

  @override
  State<CommuneDetailScreen> createState() => _CommuneDetailScreenState();
}

class _CommuneDetailScreenState extends State<CommuneDetailScreen> {
  final CommuneModel _commune = CommuneModel.sample();
  String _selectedFilter = 'Tout';
  final List<String> _filters = ['Tout', 'Adjamé Centre', 'bracoidi'];

  List<ProjectModel> get _filteredProjets {
    if (_selectedFilter == 'Tout') return _commune.projets;
    return _commune.projets
        .where((p) => p.localisation.contains(_selectedFilter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const BudgetAppBar(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Focus commune card
          _FocusCommuneCard(commune: _commune),

          // Filter tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final isSelected = f == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = f),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.white,
                        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Text(
                        f,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Projets en cours
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SectionHeader(
              title: 'Projets en cours',
              actionLabel: 'Voir tout',
              onAction: () {},
            ),
          ),

          ..._filteredProjets.map((p) => _ProjetCard(projet: p)).toList(),

          // Map section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: CommuneMapWidget(commune: _commune, height: 200),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── FOCUS COMMUNE CARD ────────────────────────────────────────────────────
class _FocusCommuneCard extends StatelessWidget {
  final CommuneModel commune;
  const _FocusCommuneCard({required this.commune});

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
          Text(
            'Détails de la Commune',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Focus\nCommune:\n${commune.name}',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),

          // Gauge circle
          Row(
            children: [
              _CircularGauge(percent: commune.tauxExecution / 100),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taux d\'exécution\nglobal',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commune.visionLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularGauge extends StatelessWidget {
  final double percent;
  const _CircularGauge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            backgroundColor: AppColors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            strokeWidth: 7,
          ),
          Text(
            '${(percent * 100).toInt()}%',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROJECT CARD ──────────────────────────────────────────────────────────
class _ProjetCard extends StatelessWidget {
  final ProjectModel projet;
  const _ProjetCard({required this.projet});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/projet/${projet.id}'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.construction, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              projet.categorie.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                            Text(
                              projet.titre,
                              style: AppTextStyles.titleLarge.copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.qr_code, size: 20, color: AppColors.textHint),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StatusChip(
                    label: projet.statut == 'en_cours' ? 'EN PROGRESSION' : projet.statut.toUpperCase(),
                    statut: projet.statut,
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: projet.progressionGlobale / 100,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation(
                        projet.statut == 'livré' ? AppColors.success : AppColors.accent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${projet.progressionGlobale.toInt()}%',
                      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // Details button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    projet.localisation,
                    style: AppTextStyles.caption,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    ),
                    child: Text(
                      'Détails',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COMMUNE MAP CARD ──────────────────────────────────────────────────────
class _CommuneMapCard extends StatelessWidget {
  final CommuneModel commune;
  const _CommuneMapCard({required this.commune});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      height: 140,
      child: Stack(
        children: [
          // Grid pattern (map simulation)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusL),
            child: CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _MapGridPainter(),
            ),
          ),
          // Label
          Positioned(
            bottom: 10,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 12, color: AppColors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Explorer la carte interactive',
                    style: AppTextStyles.caption.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
          // Commune name overlay
          Positioned(
            top: 14,
            left: 14,
            child: Text(
              commune.name.toUpperCase(),
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.white.withOpacity(0.3),
                fontSize: 28,
                letterSpacing: 3,
              ),
            ),
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
      ..color = AppColors.primaryLight.withOpacity(0.3)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
