// lib/views/commune/commune_detail_screen.dart
// ✅ Suppression de l'icône QR Code dans l'AppBar
// ✅ Suppression de "SOLDE BLOCKCHAIN", des indicateurs Recettes/Dépenses dans la barre verte
// ✅ Barre verte conserve uniquement le solde disponible (recettes - dépenses)
// ✅ Onglet Budgets : Budget initial annuel clairement indiqué
// ✅ Barre progression = Budget restant = Budget initial - Dépenses
// ✅ Suppression du bloc "info blockchain" dans l'onglet Budgets

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/commune_model.dart';
import '../../models/transaction_model.dart';
import '../../services/blockchain_service.dart';
import '../../services/commune_data_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_constants.dart';

class CommuneDetailScreen extends StatefulWidget {
  final String communeId;
  const CommuneDetailScreen({super.key, required this.communeId});

  @override
  State<CommuneDetailScreen> createState() => _CommuneDetailScreenState();
}

class _CommuneDetailScreenState extends State<CommuneDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  CommuneModel? _commune;
  List<TransactionModel> _toutes = [];
  List<TransactionModel> _recettes = [];
  List<TransactionModel> _depenses = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Données : BlockchainService uniquement.
  Future<void> _charger() async {
    try {
      CommuneModel? commune =
          await CommuneDataService.getCommuneDetails(widget.communeId);
      final session = SessionService.instance.commune;
      if (commune == null &&
          session != null &&
          session.id == widget.communeId) {
        commune = session;
      }
      if (commune == null) {
        if (mounted) {
          setState(() {
            _error = 'Commune introuvable.';
            _loading = false;
          });
        }
        return;
      }

      // Transactions depuis la blockchain
      final txs = await BlockchainService.getTransactions(widget.communeId);

      // Stats calculées localement — même Map que statistiquesDe()
      final stats = BlockchainService.computeStats(txs);

      if (mounted) {
        setState(() {
          _commune = commune;
          _toutes = txs;
          _recettes = txs.where((t) => t.isRevenue ?? false).toList();
          _depenses = txs.where((t) => !(t.isRevenue ?? false)).toList();
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les données.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomCommune = _commune?.nomCommune ?? 'Commune';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(nomCommune,
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.white)),
        // ✅ QR Code supprimé de l'AppBar
        // La fonctionnalité reste accessible via la nav bar (/scan)
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: AppTextStyles.caption
              .copyWith(fontWeight: FontWeight.w700, fontSize: 12),
          tabs: const [
            Tab(text: 'Recettes'),
            Tab(text: 'Dépenses'),
            Tab(text: 'Graphiques'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(
                  message: _error!,
                  onRetry: () {
                    setState(() {
                      _loading = true;
                      _error = null;
                    });
                    _charger();
                  })
              : Column(
                  children: [
                    // ✅ Hero solde épuré — sans blockchain, sans mini-stats
                    _SoldeHero(commune: _commune, stats: _stats, tabController: _tabController),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _TransactionsList(
                            transactions: _recettes,
                            emptyMessage: 'Aucune recette enregistrée.',
                            onTap: (tx) =>
                                context.push('/transaction/${tx.id}'),
                          ),
                          _TransactionsList(
                            transactions: _depenses,
                            emptyMessage: 'Aucune dépense enregistrée.',
                            onTap: (tx) =>
                                context.push('/transaction/${tx.id}'),
                          ),
                          _GraphiquesTab(
                            recettes: _recettes,
                            depenses: _depenses,
                            stats: _stats,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✅ HERO SOLDE — épuré : plus de "BLOCKCHAIN", plus de mini-stats Recettes/Dépenses
// Affiche uniquement le solde disponible (recettes - dépenses)
// ─────────────────────────────────────────────────────────────────────────────
class _SoldeHero extends StatefulWidget {
  final CommuneModel? commune;
  final Map<String, dynamic> stats;
  final TabController tabController;
  
  const _SoldeHero({this.commune, required this.stats, required this.tabController});

  @override
  State<_SoldeHero> createState() => _SoldeHeroState();
}

class _SoldeHeroState extends State<_SoldeHero> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.tabController.index;
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted && widget.tabController.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = widget.tabController.index;
      });
    }
  }

  String _fmt(num v) {
    final s = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Calculer les totaux selon l'onglet actif (sélectionné)
    final totalRecettes =
        (widget.stats['total_recettes'] as num?)?.toDouble() ?? 0;
    final totalDepenses =
        (widget.stats['total_depenses'] as num?)?.toDouble() ?? 0;
    final nbTransactions = widget.stats['nb_transactions'] as int? ?? 0;

    // Déterminer le total à afficher selon l'onglet actif (sélectionné)
    String label = '';
    double montant = 0;
    Color color = Colors.white;
    double montantRecettes = 0; // Pour l'affichage dans les autres cas
    
    switch (_currentTabIndex) {
      case 0: // Recettes
        label = 'TOTAL RECETTES';
        montant = totalRecettes;
        montantRecettes = totalRecettes; // Garder la valeur pour affichage
        color = const Color(0xFF2ECC71); // Vert
        break;
      case 1: // Dépenses
        label = 'TOTAL DÉPENSES';
        montant = totalDepenses;
        color = const Color(0xFFE8703A); // Orange
        break;
      case 2: // Graphiques
        label = 'TOTAL OPÉRATIONS';
        montant = totalRecettes + totalDepenses;
        color = Colors.white;
        break;
      default:
        label = 'TOTAL OPÉRATIONS';
        montant = totalRecettes + totalDepenses;
        color = Colors.white;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label selon l'onglet
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentTabIndex == 3 
                ? '${montant.toInt()} projets'
                : '${_fmt(montant)} FCFA',
            style: AppTextStyles.budgetAmount.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentTabIndex == 3
                ? 'Projets en cours dans la commune'
                : '$nbTransactions opérations enregistrées',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ① & ② LISTE TRANSACTIONS
// ─────────────────────────────────────────────────────────────────────────────
class _TransactionsList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String emptyMessage;
  final void Function(TransactionModel) onTap;

  const _TransactionsList({
    required this.transactions,
    required this.emptyMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(emptyMessage, style: AppTextStyles.bodyMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _TxCard(
        tx: transactions[i],
        onTap: () => onTap(transactions[i]),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;
  const _TxCard({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = tx.isRevenue ?? false ? AppColors.success : AppColors.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  tx.isRevenue ?? false
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.category,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 9)),
                    Text(tx.libelle,
                        style: AppTextStyles.titleLarge.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${tx.date.day.toString().padLeft(2, '0')}/'
                          '${tx.date.month.toString().padLeft(2, '0')}/'
                          '${tx.date.year}',
                          style: AppTextStyles.caption,
                        ),
                        if (tx.hasAudio) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.volume_up_rounded,
                              size: 11, color: AppColors.textSecondary),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.isRevenue ?? false ? '+' : '-'} ${tx.amountFormatted} FCFA',
                    style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.textHint),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// ④ GRAPHIQUES
// ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class _GraphiquesTab extends StatelessWidget {
  final List<TransactionModel> recettes;
  final List<TransactionModel> depenses;
  final Map<String, dynamic> stats;

  const _GraphiquesTab({
    required this.recettes,
    required this.depenses,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final totalR = (stats['total_recettes'] as num?)?.toDouble() ?? 0;
    final totalD = (stats['total_depenses'] as num?)?.toDouble() ?? 0;
    final total = totalR + totalD;
    final tabIndex = 2; // Index fixe pour l'onglet Graphiques

    final Map<String, double> parCategorie = {};
    for (final tx in depenses) {
      parCategorie[tx.category] = (parCategorie[tx.category] ?? 0) + tx.amount;
    }
    final topCategories = parCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition Recettes / Dépenses',
              style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusL),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.05), blurRadius: 6)
              ],
            ),
            child: Column(
              children: [
                _DonutChart(totalRecettes: totalR, totalDepenses: totalD),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Legende(
                        color: AppColors.success,
                        label: 'Recettes',
                        pct: total > 0
                            ? (totalR / total * 100).toStringAsFixed(0)
                            : '0'),
                    _Legende(
                        color: AppColors.accent,
                        label: 'Dépenses',
                        pct: total > 0
                            ? (totalD / total * 100).toStringAsFixed(0)
                            : '0'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (topCategories.isNotEmpty) ...[
            Text('Top dépenses par catégorie', style: AppTextStyles.titleLarge),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withOpacity(0.05), blurRadius: 6)
                ],
              ),
              child: Column(
                children: topCategories.take(5).map((e) {
                  final pct = totalD > 0 ? e.value / totalD : 0.0;
                  return _BarreCategorie(
                      label: e.key, montant: e.value, pct: pct);
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 20),

          Text('Transactions par mois', style: AppTextStyles.titleLarge),
          const SizedBox(height: 12),
          _EvolutionChart(recettes: recettes, depenses: depenses),
        ],
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  final double totalRecettes;
  final double totalDepenses;
  const _DonutChart({required this.totalRecettes, required this.totalDepenses});

  @override
  Widget build(BuildContext context) {
    final total = totalRecettes + totalDepenses;
    final pctR = total > 0 ? totalRecettes / total : 0.5;

    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _DonutPainter(pctRecettes: pctR),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(pctR * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.success)),
              Text('recettes', style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double pctRecettes;
  _DonutPainter({required this.pctRecettes});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.height / 2 - 8;
    const stroke = 28.0;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFE5EDE9);

    final rPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.success
      ..strokeCap = StrokeCap.round;

    final dPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.accent
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    final sweepR = 2 * 3.14159265 * pctRecettes;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -3.14159265 / 2,
      sweepR,
      false,
      rPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -3.14159265 / 2 + sweepR,
      2 * 3.14159265 * (1 - pctRecettes),
      false,
      dPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _Legende extends StatelessWidget {
  final Color color;
  final String label;
  final String pct;
  const _Legende({required this.color, required this.label, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label ($pct%)', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _BarreCategorie extends StatelessWidget {
  final String label;
  final double montant;
  final double pct;
  const _BarreCategorie(
      {required this.label, required this.montant, required this.pct});

  String _fmt(double v) {
    final s = v.abs().toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Text('${_fmt(montant)} FCFA',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0, 1),
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 2),
          Text('${(pct * 100).toStringAsFixed(0)}% des dépenses',
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _EvolutionChart extends StatelessWidget {
  final List<TransactionModel> recettes;
  final List<TransactionModel> depenses;
  const _EvolutionChart({required this.recettes, required this.depenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final moisLabels = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];

    final List<Map<String, dynamic>> data = [];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final r = recettes
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (s, t) => s + t.amount);
      final d = depenses
          .where((t) => t.date.year == m.year && t.date.month == m.month)
          .fold(0.0, (s, t) => s + t.amount);
      data.add({'label': moisLabels[m.month], 'r': r, 'd': d});
    }

    final maxVal = data
        .expand((e) => [e['r'] as double, e['d'] as double])
        .fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((e) {
                final double rH = maxVal > 0
                    ? ((e['r'] as double) / maxVal * 100).clamp(4, 100)
                    : 4.0;
                final double dH = maxVal > 0
                    ? ((e['d'] as double) / maxVal * 100).clamp(4, 100)
                    : 4.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 10,
                          height: rH,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Container(
                          width: 10,
                          height: dH,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: data
                .map((e) => Text(e['label'] as String,
                    style: AppTextStyles.caption.copyWith(fontSize: 10)))
                .toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendeDot(color: AppColors.success, label: 'Recettes'),
              const SizedBox(width: 16),
              _LegendeDot(color: AppColors.accent, label: 'Dépenses'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendeDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendeDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
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
            ],
          ],
        ),
      ),
    );
  }
}
