// lib/controllers/commune_controller.dart
// Commune par défaut : Cocody
// Les transactions blockchain = projets (recettes & dépenses)

import 'package:flutter/material.dart';
import '../models/commune_model.dart';
import '../models/blockchain_model.dart';
import '../services/api_service.dart';

class CommuneController extends ChangeNotifier {
  // ── Commune par défaut : Cocody ───────────────────────────────
  static const String defaultCommune = 'cocody';
  static const String defaultCommuneLabel = 'Commune Cocody';

  CommuneModel _commune = CommuneModel.cocody();
  String _selectedFilter = 'Tout';
  bool _isLoading = false;

  // ── Données blockchain (= projets financiers) ─────────────────
  CommuneBalanceModel? _balance;
  List<BlockchainTxModel> _transactions = [];
  bool _isLoadingBlockchain = false;
  String? _blockchainError;

  // ── Filtre actif sur les transactions ─────────────────────────
  String _txFilter = 'Tout'; // 'Tout' | 'recette' | 'dépense'

  CommuneModel get commune => _commune;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String get txFilter => _txFilter;

  CommuneBalanceModel? get balance => _balance;
  List<BlockchainTxModel> get transactions => _transactions;
  bool get isLoadingBlockchain => _isLoadingBlockchain;
  String? get blockchainError => _blockchainError;

  // ── Transactions filtrées (= "projets" à afficher) ────────────
  List<BlockchainTxModel> get filteredTransactions {
    if (_txFilter == 'Tout') return _transactions;
    return _transactions.where((t) => t.type == _txFilter).toList();
  }

  // Recettes et dépenses séparées
  List<BlockchainTxModel> get recettes =>
      _transactions.where((t) => t.isRevenue).toList();
  List<BlockchainTxModel> get depenses =>
      _transactions.where((t) => !t.isRevenue).toList();

  // Totaux calculés depuis les transactions blockchain
  int get totalRecettes => recettes.fold(0, (s, t) => s + t.amount);
  int get totalDepenses => depenses.fold(0, (s, t) => s + t.amount);
  int get solde => totalRecettes - totalDepenses;

  // Taux d'exécution = dépenses / recettes (si recettes > 0)
  double get tauxExecution => totalRecettes > 0
      ? (totalDepenses / totalRecettes * 100).clamp(0, 100)
      : 0;

  // Nombre total de transactions
  int get nbTransactions => _transactions.length;

  // Projets mock filtrés (garde la compatibilité home_screen)
  List<ProjectModel> get filteredProjets {
    if (_selectedFilter == 'Tout') return _commune.projets;
    return _commune.projets
        .where((p) =>
            p.commune == _selectedFilter || p.categorie == _selectedFilter)
        .toList();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setTxFilter(String filter) {
    _txFilter = filter;
    notifyListeners();
  }

  // ── Chargement principal — défaut Cocody ──────────────────────
  Future<void> loadCommune(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _commune = await ApiService.instance.getCommune(id);
    } catch (_) {
      // Garde le sample Cocody en cas d'erreur réseau
      _commune = CommuneModel.cocody();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Blockchain en parallèle — non bloquant
    _loadBlockchainData(id);
  }

  // ── Blockchain : balance + transactions (= projets) ───────────
  Future<void> _loadBlockchainData(String communeKey) async {
    _isLoadingBlockchain = true;
    _blockchainError = null;
    _transactions = [];
    notifyListeners();

    try {
      final results = await Future.wait([
        ApiService.instance.getCommuneBalance(communeKey),
        ApiService.instance.getCommuneTransactions(communeKey),
      ]);

      // Debug
      // Debug
      _balance = results[0] as CommuneBalanceModel;

      _transactions = results[1] as List<BlockchainTxModel>;
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        _blockchainError = 'Accès refusé : wallet non autorisé';
      } else if (e.statusCode == 500) {
        _blockchainError = 'Blockchain temporairement indisponible';
      } else {
        _blockchainError = 'Données blockchain indisponibles';
      }
    } catch (_) {
      _blockchainError = 'Données blockchain indisponibles';
    } finally {
      _isLoadingBlockchain = false;
      notifyListeners();
    }
  }

  Future<void> refreshBlockchain(String communeKey) =>
      _loadBlockchainData(communeKey);
}
