// lib/views/commune/commune_detail_screen.dart
// Les transactions blockchain sont affichées comme "projets"
// Commune par défaut : Cocody

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:budgetouvert/models/blockchain_model.dart';
import 'package:budgetouvert/controllers/app_controller.dart';
import 'package:budgetouvert/controllers/commune_controller.dart';
import 'package:budgetouvert/utils/app_constants.dart';
import 'package:budgetouvert/widgets/shared_widgets.dart';
import 'package:budgetouvert/widgets/commune_map_widget.dart';
import 'package:budgetouvert/models/commune_model.dart';

class CommuneDetailScreen extends StatefulWidget {
  const CommuneDetailScreen({super.key});

  @override
  State<CommuneDetailScreen> createState() => _CommuneDetailScreenState();
}

class _CommuneDetailScreenState extends State<CommuneDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // ✅ Défaut : cocody
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
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
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
                      // En-tête commune
                      _FocusCommuneCard(commune: commune, ctrl: ctrl),

                      // ── Solde blockchain ──────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _BalanceCard(
                          balance: ctrl.balance,
                          isLoading: ctrl.isLoadingBlockchain,
                          error: ctrl.blockchainError,
                        ),
                      ),

                      // ── Filtres transactions (= projets) ──────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _TxFilterRow(ctrl: ctrl),
                      ),

                      // ── Titre section ─────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: SectionHeader(
                          title: _sectionTitle(ctrl),
                          actionLabel: ctrl.transactions.isEmpty
                              ? null
                              : 'Voir tout',
                          onAction: () {},
                        ),
                      ),

                      // ── Liste transactions = projets ───────────
                      _TransactionsList(ctrl: ctrl),

                      // ── Carte OSM ─────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: CommuneMapWidget(
                            commune: commune, height: 200),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  String _sectionTitle(CommuneController ctrl) {
    switch (ctrl.txFilter) {
      case 'recette':
        return 'Recettes (${ctrl.recettes.length})';
      case 'dépense':
        return 'Dépenses (${ctrl.depenses.length})';
      default:
        return 'Tous les mouvements (${ctrl.nbTransactions})';
    }
  }
}

// ─── FILTRE TRANSACTIONS ──────────────────────────────────────────────────
class _TxFilterRow extends StatelessWidget {
  final CommuneController ctrl;
  const _TxFilterRow({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('Tout', 'Tout'),
      ('Recettes', 'recette'),
      ('Dépenses', 'dépense'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final label = f.$1;
          final value = f.$2;
          final isSelected = ctrl.txFilter == value;
          return GestureDetector(
            onTap: () => ctrl.setTxFilter(value),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.primary : AppColors.white,
                borderRadius:
                    BorderRadius.circular(AppDimens.radiusFull),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.divider,
                ),
              ),
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textPrimary,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── LISTE TRANSACTIONS = PROJETS ─────────────────────────────────────────
class _TransactionsList extends StatelessWidget {
  final CommuneController ctrl;
  const _TransactionsList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoadingBlockchain) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (ctrl.blockchainError != null && ctrl.transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _BlockchainErrorTile(message: ctrl.blockchainError!),
      );
    }

    final txs = ctrl.filteredTransactions;

    if (txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: Center(
            child: Text(
              'Aucune transaction enregistrée',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    return Column(
      children: txs
          .map((tx) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _ProjetTxCard(tx: tx),
              ))
          .toList(),
    );
  }
}

// ─── CARTE TRANSACTION = PROJET ───────────────────────────────────────────
// Reprend le visuel de _ProjetCard mais alimenté par BlockchainTxModel
class _ProjetTxCard extends StatelessWidget {
  final BlockchainTxModel tx;
  const _ProjetTxCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isRev = tx.isRevenue;
    final color = isRev ? AppColors.success : AppColors.accent;

    return Container(
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
                    // Icône type
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isRev
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        size: 18,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.category.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            tx.description,
                            style: AppTextStyles.titleLarge
                                .copyWith(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Montant
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isRev ? '+' : '-'} ${tx.amountFormatted}',
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text('FCFA',
                            style: AppTextStyles.caption
                                .copyWith(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Badge type + date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusFull),
                      ),
                      child: Text(
                        isRev
                            ? 'RECETTE'
                            : 'DÉPENSE',
                        style: AppTextStyles.caption.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(tx.date, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),

          // Pied de carte : hash blockchain
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.link,
                        size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      tx.hashShort,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
                Text(
                  'ID #${tx.id}',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FOCUS COMMUNE CARD ───────────────────────────────────────────────────
class _FocusCommuneCard extends StatelessWidget {
  final CommuneModel commune;
  final CommuneController ctrl;
  const _FocusCommuneCard(
      {required this.commune, required this.ctrl});

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
            'Détails de la commune',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Focus\nCommune :\n${commune.name}',
            style: AppTextStyles.displayMedium.copyWith(
              color: AppColors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Jauge taux d'exécution calculé depuis la blockchain
              _CircularGauge(
                  percent: ctrl.tauxExecution / 100),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Taux d\'exécution\n(dépenses/recettes)',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    commune.visionLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ctrl.nbTransactions} transactions enregistrées',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white60,
                      fontSize: 11,
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
            value: percent.clamp(0.0, 1.0),
            backgroundColor: AppColors.white.withOpacity(0.2),
            valueColor:
                const AlwaysStoppedAnimation(AppColors.accent),
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

// ─── BALANCE CARD ─────────────────────────────────────────────────────────
class _BalanceCard extends StatelessWidget {
  final CommuneBalanceModel? balance;
  final bool isLoading;
  final String? error;

  const _BalanceCard({
    required this.balance,
    required this.isLoading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final isDeficit = balance?.isDeficit ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDeficit
              ? [
                  const Color(0xFF8B1A1A),
                  const Color(0xFFB33A3A),
                ]
              : [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDeficit ? Icons.warning_amber : Icons.link,
                size: 14,
                color: Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                'SOLDE BLOCKCHAIN EN TEMPS RÉEL',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white60,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white54, strokeWidth: 2),
            )
          else if (error != null && balance == null)
            Text('Indisponible',
                style: AppTextStyles.headlineLarge
                    .copyWith(color: Colors.white54, fontSize: 20))
          else
            Text(
              balance?.balanceFormatted ?? '—',
              style: AppTextStyles.budgetAmount,
            ),
          const SizedBox(height: 6),
          Text(
            isDeficit
                ? 'Déficit : les dépenses dépassent les recettes'
                : 'Recettes − Dépenses enregistrées sur la blockchain',
            style:
                AppTextStyles.caption.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

// ─── ERREUR BLOCKCHAIN ────────────────────────────────────────────────────
class _BlockchainErrorTile extends StatelessWidget {
  final String message;
  const _BlockchainErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border:
            Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
