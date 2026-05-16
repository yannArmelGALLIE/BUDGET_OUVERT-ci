// lib/services/commune_data_service.dart
//
// Source unique : blockchain (BudgetRegistry via BlockchainService).
// Aucun appel API REST. Aucune donnée statique.
//
// getCommunes() :
//   Pour chaque nom dans BlockchainConfig.kCommunesOnChain,
//   appelle getTransactionCount() on-chain.
//   → retourne uniquement les communes qui ont count > 0
//     (= actives sur la blockchain) avec leur solde réel.
//
// getCommuneDetails() :
//   Appelle getBalance() on-chain pour le solde exact.

import '../models/commune_model.dart';
import '../utils/blockchain_config.dart';
import 'blockchain_service.dart';

class CommuneDataService {
  CommuneDataService._();

  /// Retourne les communes actives sur la blockchain.
  ///
  /// "Active" = getTransactionCount(nom) > 0 sur le contrat.
  /// Si [recherche] est fourni, filtre sur le nom.
  static Future<List<CommuneModel>> getCommunes({String? recherche}) async {
    final noms = BlockchainConfig.kCommunesOnChain;
    final resultats = <CommuneModel>[];

    await Future.wait(
      noms.map((nom) async {
        try {
          final count = await BlockchainService.getTransactionCount(nom);
          if (count == 0) return; // vide on-chain → ignorée

          final solde = await BlockchainService.getBalance(nom);

          resultats.add(CommuneModel(
            id: nom, // nom on-chain = clé du contrat = ID
            nomCommune: nom,
            departement: '',
            region: '',
            statutActif: true,
            budget: solde >= 0 ? solde : 0,
            budgetUtilise: solde < 0 ? solde.abs() : 0,
          ));
        } catch (_) {
          // Commune inaccessible on-chain → ignorée silencieusement
        }
      }),
    );

    resultats.sort((a, b) => a.nomCommune.compareTo(b.nomCommune));

    if (recherche != null && recherche.trim().isNotEmpty) {
      final q = recherche.toLowerCase().trim();
      return resultats
          .where((c) => c.nomCommune.toLowerCase().contains(q))
          .toList();
    }

    return resultats;
  }

  /// Retourne le détail d'une commune depuis la blockchain.
  /// [communeId] = nom on-chain (ex : 'Commune Abobo').
  static Future<CommuneModel?> getCommuneDetails(String communeId) async {
    try {
      final solde = await BlockchainService.getBalance(communeId);
      return CommuneModel(
        id: communeId,
        nomCommune: communeId,
        departement: '',
        region: '',
        statutActif: true,
        budget: solde >= 0 ? solde : 0,
        budgetUtilise: solde < 0 ? solde.abs() : 0,
      );
    } catch (_) {
      return null;
    }
  }
}
