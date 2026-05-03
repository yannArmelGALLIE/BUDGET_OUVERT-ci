// lib/views/home/home_screen.dart
// Commune par défaut : Cocody
// Le hero card affiche les données blockchain (balance + nb transactions)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/commune_controller.dart';
import '../../utils/app_constants.dart';
import '../../widgets/shared_widgets.dart';
import '../../models/commune_model.dart';
import '../../models/blockchain_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ✅ Commune par défaut : cocody (fallback si user non connecté)
      final communeKey =
          context.read<AppController>().currentUser?.commune ??
              CommuneController.defaultCommune;
      context.read<CommuneController>().loadCommune(communeKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuneController>(
      builder: (context, ctrl, _) {
        final commune = ctrl.commune;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const BudgetAppBar(),
          body: ctrl.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () {
                    final key =
                        context.read<AppController>().currentUser?.commune ??
                            CommuneController.defaultCommune;
                    return ctrl.loadCommune(key);
                  },
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Hero card avec données blockchain live
                      _BudgetHeroCard(ctrl: ctrl, commune: commune),

                      // Actions rapides
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
                              icon: Icons.receipt_long_outlined,
                              label: 'Transactions',
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

                      // Résumé financier (recettes / dépenses)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: SectionHeader(
                          title: 'Résumé financier',
                          actionLabel: 'Voir tout',
                          onAction: () => context.go('/communes'),
                        ),
                      ),
                      _FinancialSummaryCard(ctrl: ctrl),

                      // Dernières transactions (= projets)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: SectionHeader(title: 'Dernières transactions'),
                      ),
                      _RecentTransactionsRow(ctrl: ctrl),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

// ─── BUDGET HERO — données blockchain live ────────────────────────────────
class _BudgetHeroCard extends StatelessWidget {
  final CommuneController ctrl;
  final CommuneModel commune;
  const _BudgetHeroCard({required this.ctrl, required this.commune});

  @override
  Widget build(BuildContext context) {
    final balance = ctrl.balance;
    final isLoading = ctrl.isLoadingBlockchain;

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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        commune.visionLabel.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.link,
                            size: 12, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          'BLOCKCHAIN',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Solde disponible',
                    style:
                        AppTextStyles.caption.copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white54, strokeWidth: 2),
                      )
                    : Text(
                        balance?.balanceFormatted ?? '— FCFA',
                        style: AppTextStyles.budgetAmount,
                      ),
                const SizedBox(height: 16),
                // Barre progression taux d'exécution (depuis blockchain)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ctrl.tauxExecution / 100,
                    backgroundColor: AppColors.white.withOpacity(0.2),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Dépenses / Recettes',
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white70)),
                    Text(
                      '${ctrl.tauxExecution.toInt()}%',
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
}

// ─── RÉSUMÉ FINANCIER ─────────────────────────────────────────────────────
class _FinancialSummaryCard extends StatelessWidget {
  final CommuneController ctrl;
  const _FinancialSummaryCard({required this.ctrl});

  String _fmt(int v) {
    final s = v.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: ctrl.isLoadingBlockchain
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child:
                    CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: 'Recettes',
                    value: '${_fmt(ctrl.totalRecettes)} FCFA',
                    icon: Icons.arrow_downward_rounded,
                    color: AppColors.success,
                    count: ctrl.recettes.length,
                  ),
                ),
                Container(
                    width: 1, height: 50, color: AppColors.divider),
                Expanded(
                  child: _SummaryItem(
                    label: 'Dépenses',
                    value: '${_fmt(ctrl.totalDepenses)} FCFA',
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.accent,
                    count: ctrl.depenses.length,
                  ),
                ),
                Container(
                    width: 1, height: 50, color: AppColors.divider),
                Expanded(
                  child: _SummaryItem(
                    label: 'Transactions',
                    value: '${ctrl.nbTransactions}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    count: null,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int? count;
  const _SummaryItem(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          count != null ? '$label ($count)' : label,
          style:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── DERNIÈRES TRANSACTIONS (défilement horizontal) ───────────────────────
class _RecentTransactionsRow extends StatelessWidget {
  final CommuneController ctrl;
  const _RecentTransactionsRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoadingBlockchain) {
      return const SizedBox(
        height: 140,
        child: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final txs = ctrl.transactions.take(6).toList();

    if (txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: Text(
            ctrl.blockchainError ?? 'Aucune transaction enregistrée',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: txs.length,
        itemBuilder: (context, i) => _TxCard(tx: txs[i]),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final BlockchainTxModel tx;
  const _TxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isRev = tx.isRevenue;
    final color = isRev ? AppColors.success : AppColors.accent;

    return Container(
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
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRev ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 14,
                  color: color,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isRev ? 'Recette' : 'Dépense',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tx.category,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            tx.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${isRev ? '+' : '-'} ${tx.amountFormatted} FCFA',
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            tx.date,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── QUICK ACTION ─────────────────────────────────────────────────────────
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
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
