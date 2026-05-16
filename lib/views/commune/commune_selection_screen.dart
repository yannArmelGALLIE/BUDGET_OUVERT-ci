// lib/views/commune/commune_selection_screen.dart
// Sélection de commune — version redesignée.
// • Communes : CommuneDataService (blockchain).
// • Pagination client (8 / page) sur la liste chargée.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/app_controller.dart';
import '../../models/commune_model.dart';
import '../../services/commune_data_service.dart';
import '../../utils/app_constants.dart';

class CommuneSelectionScreen extends StatefulWidget {
  const CommuneSelectionScreen({super.key});

  @override
  State<CommuneSelectionScreen> createState() =>
      _CommuneSelectionScreenState();
}

class _CommuneSelectionScreenState extends State<CommuneSelectionScreen>
    with SingleTickerProviderStateMixin {
  // ── Recherche ────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // ── Infinite scroll ──────────────────────────────────────────────────────
  static const int _pageSize = 8;
  final List<CommuneModel> _affichees = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;

  /// Liste courante (recherche appliquée côté service).
  List<CommuneModel> _pool = [];
  bool _poolLoading = false;
  String? _poolError;

  // ── ScrollController ─────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── Animation header ─────────────────────────────────────────────────────
  late final AnimationController _headerAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut));

    _headerAnim.forward();

    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _reloadPool();
    if (!mounted) return;
    await _chargerPage();
  }

  Future<void> _reloadPool() async {
    setState(() {
      _poolLoading = true;
      _poolError = null;
    });
    try {
      _pool = await CommuneDataService.getCommunes(
        recherche: _query.isEmpty ? null : _query,
      );
      _poolError = null;
    } catch (e) {
      _poolError = e.toString();
      _pool = [];
    }
    if (mounted) {
      setState(() => _poolLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  // ── Chargement paginé ─────────────────────────────────────────────────────
  Future<void> _chargerPage() async {
    if (_isLoadingMore || !_hasMore) return;
    if (_poolLoading) return;

    setState(() => _isLoadingMore = true);


    final pool = _pool;
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, pool.length);
    final slice =
        start < pool.length ? pool.sublist(start, end) : <CommuneModel>[];

    if (mounted) {
      setState(() {
        _affichees.addAll(slice);
        _currentPage++;
        _hasMore = end < pool.length;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _chargerPage();
    }
  }

  // ── Recherche : recharge le pool puis repaginer ───────────────────────────
  void _filtrer(String q) {
    _filtrerAsync(q);
  }

  Future<void> _filtrerAsync(String q) async {
    setState(() {
      _query = q;
      _affichees.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _reloadPool();
    if (!mounted) return;
    await _chargerPage();
  }

  // ── Sélection ────────────────────────────────────────────────────────────
  Future<void> _selectionner(CommuneModel commune) async {
    if (!mounted) return;
    await context
        .read<AppController>()
        .setSelectedCommune(commune.id, commune: commune);
    if (mounted) context.go('/accueil');
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── SliverAppBar animé ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: AppColors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderContent(
                fadeAnim: _fadeAnim,
                slideAnim: _slideAnim,
              ),
              titlePadding: EdgeInsets.zero,
            ),
            title: const Text(
              'Votre commune',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // ── Barre de recherche sticky ───────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SearchBarDelegate(
              controller: _searchController,
              onChanged: _filtrer,
            ),
          ),

          // ── Compteur résultats ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                _query.isEmpty
                    ? '${_pool.length} communes disponibles'
                    : '${_pool.length} résultat${_pool.length > 1 ? 's' : ''} pour "$_query"',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          if (_poolLoading && _affichees.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_poolError != null && _affichees.isEmpty)
            SliverFillRemaining(
              child: _PoolErrorState(
                message: _poolError!,
                onRetry: _bootstrap,
              ),
            )
          else
            // ── Liste des communes ──────────────────────────────────────────
            _affichees.isEmpty && !_isLoadingMore
              ? SliverFillRemaining(
                  child: _EmptyState(query: _query),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < _affichees.length) {
                          return _CommuneCard(
                            commune: _affichees[index],
                            index: index,
                            onTap: () => _selectionner(_affichees[index]),
                          );
                        }
                        // Loader en bas
                        return _hasMore
                            ? const _BottomLoader()
                            : const _EndOfList();
                      },
                      childCount: _affichees.length + (_hasMore || _isLoadingMore ? 1 : 1),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Header animé ────────────────────────────────────────────────────────────

class _HeaderContent extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const _HeaderContent({required this.fadeAnim, required this.slideAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
        ),
      ),
      child: Stack(
        children: [
          // Motif décoratif en arrière-plan
          Positioned(
            right: -30,
            top: -20,
            child: Opacity(
              opacity: 0.06,
              child: Icon(
                Icons.location_city_rounded,
                size: 200,
                color: AppColors.white,
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 20,
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.account_balance_rounded,
                size: 140,
                color: AppColors.white,
              ),
            ),
          ),
          // Contenu principal
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded,
                                    size: 12,
                                    color: AppColors.accentLight),
                                const SizedBox(width: 4),
                                Text(
                                  'Transparence budgétaire',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accentLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sélectionnez\nvotre commune',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Consultez librement les finances publiques',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Barre de recherche sticky ────────────────────────────────────────────────

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBarDelegate({required this.controller, required this.onChanged});

  @override
  double get minExtent => 72;
  @override
  double get maxExtent => 72;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Rechercher par commune, région…',
            hintStyle: AppTextStyles.bodyMedium,
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.primary, size: 22),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textHint),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBarDelegate old) =>
      controller != old.controller || onChanged != old.onChanged;
}

// ─── Carte commune enrichie ───────────────────────────────────────────────────

class _CommuneCard extends StatelessWidget {
  final CommuneModel commune;
  final int index;
  final VoidCallback onTap;

  const _CommuneCard({
    required this.commune,
    required this.index,
    required this.onTap,
  });

  // Couleur de région pseudo-aléatoire mais stable
  Color _regionColor() {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFE07B3A),
      Color(0xFFEF4444),
      Color(0xFF06B6D4),
    ];
    return colors[commune.region.length % colors.length];
  }

  String _formatBudget(double? v) {
    if (v == null) return '—';
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)} Md';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(0)} M';
    return '${v.toStringAsFixed(0)} FCFA';
  }

  String _formatPop(int? v) {
    if (v == null) return '—';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)} k hab.';
    return '$v hab.';
  }

  @override
  Widget build(BuildContext context) {
    final regionColor = _regionColor();
    final taux = commune.tauxExecution;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ligne principale ──────────────────────────────────
                Row(
                  children: [
                    // Avatar initiale
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        commune.nomCommune.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commune.nomCommune,
                            style: AppTextStyles.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Chip région
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: regionColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  commune.region,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: regionColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Badge actif
                              if (commune.statutActif)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.success,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Text(
                                        'Actif',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textHint),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Stats ──────────────────────────────────────────────
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_outline_rounded,
                      label: _formatPop(commune.population),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.account_balance_wallet_outlined,
                      label: _formatBudget(commune.budget),
                    ),
                    const Spacer(),
                    // Taux d'exécution
                    if (commune.budget != null && commune.budget! > 0)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${taux.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: taux > 80
                                  ? AppColors.success
                                  : taux > 50
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'exécuté',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                  ],
                ),

                // ── Barre de progression taux exécution ───────────────
                if (commune.budget != null && commune.budget! > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (taux / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: AppColors.divider,
                      color: taux > 80
                          ? AppColors.success
                          : taux > 50
                              ? AppColors.warning
                              : AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Petit chip stat ──────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Loader bas de liste ──────────────────────────────────────────────────────

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Chargement…',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fin de liste ─────────────────────────────────────────────────────────────

class _EndOfList extends StatelessWidget {
  const _EndOfList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          '— Fin de la liste —',
          style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
        ),
      ),
    );
  }
}

class _PoolErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PoolErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger les communes',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.textHint),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? 'Aucune commune disponible'
                  : 'Aucun résultat pour\n"$query"',
              style: AppTextStyles.headlineMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (query.isNotEmpty)
              Text(
                'Vérifiez l\'orthographe ou essayez\nune autre région.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
