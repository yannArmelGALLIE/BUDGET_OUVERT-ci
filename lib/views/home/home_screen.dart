// lib/views/home/home_screen.dart
// Écran principal — source de données : BlockchainService uniquement.

import 'package:budget_ouvert/controllers/app_controller.dart';
import 'package:budget_ouvert/widgets/qr_info_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/commune_model.dart';
import '../../models/transaction_model.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/blockchain_service.dart';
import '../../services/commune_data_service.dart';
import '../../services/session_service.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CommuneModel? _commune;
  List<TransactionModel> _transactions = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final session = SessionService.instance;
    var commune = session.commune;

    if (commune == null) {
      if (mounted) context.go('/communes');
      return;
    }

    final rafraichi = await CommuneDataService.getCommuneDetails(commune.id);
    if (rafraichi != null) commune = rafraichi;

    try {
      final allTxs = await BlockchainService.getTransactions(commune.id);
      final txs = allTxs.take(5).toList();

      final stats = BlockchainService.computeStats(allTxs);

      if (mounted) {
        setState(() {
          _commune = commune;
          _transactions = txs;
          _stats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      // En cas d'erreur RPC on affiche quand même l'écran (stats vides)
      if (mounted) {
        setState(() {
          _commune = commune;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppController>();
    final communeName = _commune?.name ?? '…';

    // ✅ Budget initial annuel voté
    final budgetInitial = _commune?.budget ?? 0;
    // ✅ Somme des dépenses
    final totalDepenses = (_stats['total_depenses'] as num?)?.toDouble() ??
        _commune?.budgetUtilise ??
        0;
    // ✅ Budget restant = budget initial - dépenses (min 0)
    final budgetRestant =
        (budgetInitial - totalDepenses).clamp(0.0, double.infinity);
    // ✅ Taux consommation = dépenses / budget initial
    final taux = budgetInitial > 0
        ? ((totalDepenses / budgetInitial) * 100).clamp(0.0, 100.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: BudgetAppBar(
        communeName: communeName,
        showProfile: FirebaseAuthService.isLoggedIn,
        onProfileTap: () {
          final router = GoRouter.of(context);

          showModalBottomSheet(
            context: context,
            builder: (sheetContext) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FirebaseAuthService.isLoggedIn
                      ? const Text(
                          'Voulez-vous vous déconnecter ?',
                          style: TextStyle(fontSize: 14, fontFamily: "Poppins"),
                          textAlign: TextAlign.center,
                        )
                      : const Text(
                          'Voulez-vous vous connecter afin de bénéficier de fonctionnalités avancées ?',
                          style: TextStyle(fontSize: 14, fontFamily: "Poppins"),
                          textAlign: TextAlign.center,
                        ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);

                      await Future.delayed(Duration.zero);

                      if (!FirebaseAuthService.isLoggedIn) {
                        router.push('/connexion');
                      } else {
                        await FirebaseAuthService.signOut();
                        context.read<AppController>().onAuthChanged();
                        router.go('/accueil');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: FirebaseAuthService.isLoggedIn
                        ? const Text(
                            'Se déconnecter',
                            style: TextStyle(color: Colors.white),
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1C3A2F),
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF1C3A2F),
              onRefresh: _charger,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // ── Hero budget ──────────────────────────────────────
                  _BudgetHeroCard(
                    communeName: communeName,
                    budgetInitial: budgetInitial,
                    budgetRestant: budgetRestant,
                    totalDepenses: totalDepenses,
                    tauxConsommation: taux,
                  ),

                  // ── Actions rapides ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'Voir les\ndétails',
                          onTap: () =>
                              context.push('/commune/${_commune?.id ?? ''}'),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: FirebaseAuthService.isLoggedIn
                              ? Icons.flag_outlined
                              : Icons.login_rounded,
                          label: FirebaseAuthService.isLoggedIn
                              ? 'Mes\nsignalements'
                              : 'Se\nconnecter',
                          onTap: () {
                            if (FirebaseAuthService.isLoggedIn) {
                              context.push('/mes-signalements');
                            } else {
                              context.push('/connexion');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 350,
                      child: QrInfoCard(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // ── Résumé financier ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Résumé financier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              context.push('/commune/${_commune?.id ?? ''}'),
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE8703A),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _FinancialSummaryCard(stats: _stats),

                  // ── Dernières transactions ───────────────────────────
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Text(
                      'Dernières transactions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),

                  if (_transactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Center(child: Text('Aucune transaction.')),
                    )
                  else
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, i) => _TxCard(
                          tx: _transactions[i],
                          onTap: () => context
                              .push('/transaction/${_transactions[i].id}'),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

// ─── HERO CARD ────────────────────────────────────────────────────────────
class _BudgetHeroCard extends StatelessWidget {
  final String communeName;
  final double budgetInitial;
  final double budgetRestant;
  final double totalDepenses;
  final double tauxConsommation;

  const _BudgetHeroCard({
    required this.communeName,
    required this.budgetInitial,
    required this.budgetRestant,
    required this.totalDepenses,
    required this.tauxConsommation,
  });

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
    final bool alerteHaute = tauxConsommation >= 90;
    final Color barreColor =
        alerteHaute ? const Color(0xFFD64545) : const Color(0xFFE8703A);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C3A2F), Color(0xFF2D5C45)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1C3A2F).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.account_balance_rounded,
                              size: 10, color: Colors.white70),
                          SizedBox(width: 5),
                          Text(
                            'BUDGET ANNUEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${DateTime.now().year}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Budget initial',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmt(budgetInitial)} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consommation du budget',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    Text(
                      '${tauxConsommation.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: barreColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: tauxConsommation / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: barreColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: barreColor.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Dépensé',
                        value: '${_fmt(totalDepenses)} FCFA',
                        icon: Icons.arrow_upward_rounded,
                        color: const Color(0xFFE8703A),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: Colors.white.withOpacity(0.15),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _HeroStat(
                        label: 'Budget restant',
                        value: '${_fmt(budgetRestant)} FCFA',
                        color: const Color(0xFF2ECC71),
                        icon: Icons.money_rounded,
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
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  const _HeroStat({
    required this.label,
    required this.value,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── RÉSUMÉ FINANCIER ─────────────────────────────────────────────────────
class _FinancialSummaryCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _FinancialSummaryCard({required this.stats});

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
    final recettes = stats['total_recettes'] as num? ?? 0;
    final depenses = stats['total_depenses'] as num? ?? 0;
    final nb = stats['nb_transactions'] as num? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _SummaryItem(
            label: 'Recettes',
            value: '${_fmt(recettes)} FCFA',
            icon: Icons.arrow_downward_rounded,
            color: const Color(0xFF2ECC71),
          ),
          Container(width: 1, height: 50, color: const Color(0xFFEEEFF3)),
          _SummaryItem(
            label: 'Dépenses',
            value: '${_fmt(depenses)} FCFA',
            icon: Icons.arrow_upward_rounded,
            color: const Color(0xFFE8703A),
          ),
          Container(width: 1, height: 50, color: const Color(0xFFEEEFF3)),
          _SummaryItem(
            label: 'Transactions',
            value: '$nb',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFF1C3A2F),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A8FA3),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── CARTE TRANSACTION HORIZONTALE ────────────────────────────────────────
class _TxCard extends StatelessWidget {
  final TransactionModel tx;
  final VoidCallback onTap;

  const _TxCard({required this.tx, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRecette = tx.isRevenue ?? false;
    final color = isRecette ? const Color(0xFF2ECC71) : const Color(0xFFE8703A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isRecette
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 14,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isRecette ? 'Recette' : 'Dépense',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tx.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE8703A),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              tx.libelle,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${tx.date.day.toString().padLeft(2, '0')}/'
              '${tx.date.month.toString().padLeft(2, '0')}/'
              '${tx.date.year}',
              style: const TextStyle(
                color: Color(0xFF8A8FA3),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QUICK ACTION ─────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C3A2F).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF1C3A2F),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
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
