// lib/models/transaction_model.dart
// Aligné sur le MCD : id_transaction, id_commune, id_categorie,
// montant_fcfa, libelle, statut, piece_justificative_url, hash_blockchain
// + audio (depuis AUDIO_EXPLICATION embedé dans la réponse API)

class TransactionModel {
  final String id;
  final String communeId;
  final int? categorieId;
  final String category; // libellé catégorie (dénormalisé par l'API)
  final String? categorieIcone;
  final String? categorieCouleur;
  final String libelle;
  final String description;
  final double amount; // montant_fcfa
  final bool? isRevenue; // type == 'RECETTE'
  final DateTime date; // date_transaction
  final String statut; // BROUILLON | EN_ATTENTE | VALIDE | PUBLIE
  final String? pieceJustificativeUrl;
  final String? hashBlockchain;
  final String? audioUrl;
  final String? audioLangue;
  final String? reference;
  final DateTime? dateValidation;
  final DateTime? datePublication;

  const TransactionModel({
    required this.id,
    required this.communeId,
    this.categorieId,
    required this.category,
    this.categorieIcone,
    this.categorieCouleur,
    required this.libelle,
    required this.description,
    required this.amount,
    required this.isRevenue,
    required this.date,
    this.statut = 'PUBLIE',
    this.pieceJustificativeUrl,
    this.hashBlockchain,
    this.audioUrl,
    this.audioLangue,
    this.reference,
    this.dateValidation,
    this.datePublication,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Supporte à la fois les clés MCD (id_transaction, montant_fcfa)
    // et les clés API simplifiées (id, amount)
    final bool isRevenue =
        ((json['type'] as String?)?.toUpperCase() == 'RECETTE') ||
            (json['is_revenue'] == true);

    return TransactionModel(
      id: json['id_transaction'] as String? ?? json['id'] as String,
      communeId: json['id_commune'] as String? ?? json['commune_id'] as String,
      categorieId: (json['id_categorie'] as num?)?.toInt(),
      category: json['categorie_libelle'] as String? ??
          json['category'] as String? ??
          '',
      categorieIcone: json['categorie_icone'] as String?,
      categorieCouleur: json['categorie_couleur'] as String?,
      libelle:
          json['libelle'] as String? ?? json['description'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['montant_fcfa'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0,
      isRevenue: isRevenue,
      date: DateTime.parse(
          json['date_transaction'] as String? ?? json['date'] as String),
      statut: json['statut'] as String? ?? 'PUBLIE',
      pieceJustificativeUrl: json['piece_justificative_url'] as String?,
      hashBlockchain: json['hash_blockchain'] as String?,
      audioUrl: json['audio_url'] as String?,
      audioLangue: json['audio_langue'] as String?,
      reference: json['reference'] as String?,
      dateValidation: json['date_validation'] != null
          ? DateTime.tryParse(json['date_validation'] as String)
          : null,
      datePublication: json['date_publication'] != null
          ? DateTime.tryParse(json['date_publication'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_transaction': id,
        'id_commune': communeId,
        'id_categorie': categorieId,
        'categorie_libelle': category,
        'libelle': libelle,
        'description': description,
        'montant_fcfa': amount,
        'type': isRevenue == true ? 'RECETTE' : 'DEPENSE',
        'date_transaction': date.toIso8601String(),
        'statut': statut,
        'piece_justificative_url': pieceJustificativeUrl,
        'hash_blockchain': hashBlockchain,
        'audio_url': audioUrl,
        'audio_langue': audioLangue,
        'reference': reference,
        'date_validation': dateValidation?.toIso8601String(),
        'date_publication': datePublication?.toIso8601String(),
      };

  // ── Helpers ───────────────────────────────────────────────────────────
  String get amountFormatted {
    final n = amount.abs().toInt();
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String get typeLabel => isRevenue == true ? 'Recette' : 'Dépense';
  bool get hasAudio => audioUrl != null && audioUrl!.isNotEmpty;
  bool get hasJustificatif =>
      pieceJustificativeUrl != null && pieceJustificativeUrl!.isNotEmpty;
  bool get hasHash => hashBlockchain != null && hashBlockchain!.isNotEmpty;

  @override
  String toString() => 'TransactionModel($libelle, $amountFormatted FCFA)';
}
