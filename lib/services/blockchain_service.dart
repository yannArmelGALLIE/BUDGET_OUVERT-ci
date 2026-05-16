// lib/services/blockchain_service.dart
//
// Connexion au smart contract BudgetRegistry via web3dart.
//
// API publique :
//   getCommunes()               → via CommuneDataService (pas ici)
//   getTransactions(nom)        → Future<List<TransactionModel>>
//   getTransactionById(id, nom) → Future<TransactionModel?>
//   getTransactionCount(nom)    → Future<int>
//   getBalance(nom)             → Future<double>   (solde signé FCFA)
//   computeStats(txs)           → Map<String,dynamic>

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';
import '../models/transaction_model.dart';
import '../utils/blockchain_config.dart';
import '../utils/debug_console.dart';

class BlockchainService {
  BlockchainService._();

  static Web3Client? _client;
  static DeployedContract? _contract;

  static Web3Client _getClient() {
    _client ??= Web3Client(BlockchainConfig.kRpcUrl, http.Client());
    return _client!;
  }

  static Future<DeployedContract> _getContract() async {
    if (_contract != null) return _contract!;
    final abi =
        ContractAbi.fromJson(BlockchainConfig.kContractAbi, 'BudgetRegistry');
    _contract = DeployedContract(
      abi,
      EthereumAddress.fromHex(BlockchainConfig.kContractAddress),
    );
    return _contract!;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getTransactions
  // ═══════════════════════════════════════════════════════════════════════════

  /// [nomOnChain] = nom exact enregistré sur le contrat (ex : 'Commune Abobo').
  static Future<List<TransactionModel>> getTransactions(
    String nomOnChain, {
    bool logToConsole = true,
  }) async {
    try {
      final client = _getClient();
      final contract = await _getContract();
      final fn = contract.function('getTransactions');

      final result = await client.call(
          contract: contract,
          function: fn,
          params: [nomOnChain]).timeout(BlockchainConfig.kRpcTimeout);

      final rawList = result[0] as List<dynamic>;

      if (logToConsole) {
        debugLogData('Blockchain [getTransactions]', {
          'nomOnChain': nomOnChain,
          'count': rawList.length,
        });
      }

      return rawList
          .map((raw) => _txFromTuple(raw as List<dynamic>, nomOnChain))
          .toList();
    } catch (e) {
      if (kDebugMode) print('BlockchainService.getTransactions: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getTransactionById
  // ═══════════════════════════════════════════════════════════════════════════

  /// Si [nomOnChain] est fourni → 1 seul appel RPC (cas nominal depuis les écrans).
  /// Sans [nomOnChain] → parcourt toutes les communes (fallback scan QR).
  static Future<TransactionModel?> getTransactionById(
    String id, {
    String? nomOnChain,
  }) async {
    final numericId = _extractNumericId(id);
    if (numericId == null) return null;

    if (nomOnChain != null) {
      try {
        final txs = await getTransactions(nomOnChain, logToConsole: false);
        return txs.where((t) => t.id == numericId.toString()).firstOrNull;
      } catch (_) {
        return null;
      }
    }

    // Fallback : cherche dans toutes les communes connues
    for (final nom in BlockchainConfig.kCommunesOnChain) {
      try {
        final txs = await getTransactions(nom, logToConsole: false);
        final match =
            txs.where((t) => t.id == numericId.toString()).firstOrNull;
        if (match != null) return match;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getTransactionCount
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nombre de transactions enregistrées pour une commune on-chain.
  /// Utilisé par CommuneDataService pour détecter les communes actives.
  static Future<int> getTransactionCount(String nomOnChain) async {
    try {
      final client = _getClient();
      final contract = await _getContract();
      final fn = contract.function('getTransactionCount');

      final result = await client.call(
          contract: contract,
          function: fn,
          params: [nomOnChain]).timeout(BlockchainConfig.kRpcTimeout);

      return (result[0] as BigInt).toInt();
    } catch (e) {
      if (kDebugMode) print('BlockchainService.getTransactionCount: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getBalance
  // ═══════════════════════════════════════════════════════════════════════════

  /// Solde net signé (recettes - dépenses) en FCFA depuis le contrat.
  /// Valeur positive = excédent, négative = déficit.
  static Future<double> getBalance(String nomOnChain) async {
    try {
      final client = _getClient();
      final contract = await _getContract();
      final fn = contract.function('getBalance');

      final result = await client.call(
          contract: contract,
          function: fn,
          params: [nomOnChain]).timeout(BlockchainConfig.kRpcTimeout);

      final balance = result[0] as BigInt;

      debugLogData('Blockchain [getBalance]', {
        'nomOnChain': nomOnChain,
        'balanceWei': balance.toString(),
      });

      return balance.toDouble();
    } catch (e) {
      if (kDebugMode) print('BlockchainService.getBalance: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // computeStats
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcul Dart depuis la liste de transactions.
  static Map<String, dynamic> computeStats(List<TransactionModel> txs) {
    double totalRecettes = 0;
    double totalDepenses = 0;

    for (final tx in txs) {
      if (tx.isRevenue == true) {
        totalRecettes += tx.amount;
      } else {
        totalDepenses += tx.amount;
      }
    }

    return {
      'total_recettes': totalRecettes,
      'total_depenses': totalDepenses,
      'solde': totalRecettes - totalDepenses,
      'nb_transactions': txs.length,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNE — décodage tuple Solidity → TransactionModel
  // ═══════════════════════════════════════════════════════════════════════════

  // struct Transaction {
  //   uint256 id;          → [0] BigInt
  //   string  commune;     → [1] String  (nom on-chain)
  //   TxType  txType;      → [2] BigInt  (0=REVENUE, 1=EXPENSE)
  //   string  category;    → [3] String
  //   uint256 amount;      → [4] BigInt  (FCFA)
  //   uint256 timestamp;   → [5] BigInt  (secondes Unix)
  //   string  description; → [6] String
  //   address recorder;    → [7] EthereumAddress (non stocké)
  // }
  static TransactionModel _txFromTuple(List<dynamic> t, String nomOnChain) {
    final id = (t[0] as BigInt).toString();
    final txTypeRaw = (t[2] as BigInt).toInt();
    final amount = (t[4] as BigInt).toDouble();
    final timestampSec = (t[5] as BigInt).toInt();
    final category = t[3] as String;
    final description = t[6] as String;

    return TransactionModel(
      id: id,
      communeId: nomOnChain, // nom on-chain = ID dans cette architecture
      categorieId: null,
      category: category,
      libelle: description,
      description: description,
      amount: amount,
      isRevenue: txTypeRaw == 0, // TxType.REVENUE = 0
      date: DateTime.fromMillisecondsSinceEpoch(timestampSec * 1000),
      statut: 'PUBLIE',
      hashBlockchain: null, // disponible via event logs uniquement
      audioUrl: null,
      reference: 'BC-$id',
    );
  }

  static int? _extractNumericId(String id) {
    final direct = int.tryParse(id);
    if (direct != null) return direct;
    final match = RegExp(r'(\d+)$').firstMatch(id);
    if (match != null) return int.tryParse(match.group(1)!);
    return null;
  }

  static void dispose() {
    _client?.dispose();
    _client = null;
    _contract = null;
  }
}
