// lib/models/commune_model.dart
// Aligné sur les noms de champs du MCD :
// nom_commune, departement, region, statut_actif, logo_url, email_contact

class CommuneModel {
  final String id;
  final String nomCommune;
  final String departement;
  final String region;
  final int? population;
  final String? emailContact;
  final String? telephone;
  final String? logoUrl;
  final bool statutActif;
  final double? budget;        // calculé côté API (total recettes)
  final double? budgetUtilise; // calculé côté API (total dépenses)
  final DateTime? dateInscription;

  const CommuneModel({
    required this.id,
    required this.nomCommune,
    required this.departement,
    required this.region,
    this.population,
    this.emailContact,
    this.telephone,
    this.logoUrl,
    this.statutActif = true,
    this.budget,
    this.budgetUtilise,
    this.dateInscription,
  });

  // ── Getters calculés ─────────────────────────────────────────────────────
  double get tauxExecution =>
      (budget != null && budgetUtilise != null && budget! > 0)
          ? (budgetUtilise! / budget!) * 100
          : 0.0;

  double get budgetRestant => (budget ?? 0) - (budgetUtilise ?? 0);

  // Alias court pour l'affichage (compatibilité avec les widgets existants)
  String get name => nomCommune;

  // ── Désérialisation — lit les vrais noms du MCD ───────────────────────
  factory CommuneModel.fromJson(Map<String, dynamic> json) {
    return CommuneModel(
      id: json['id_commune'] as String? ?? json['id'] as String,
      nomCommune: json['nom_commune'] as String? ?? json['name'] as String? ?? '',
      departement: json['departement'] as String? ?? '',
      region: json['region'] as String? ?? '',
      population: (json['population'] as num?)?.toInt(),
      emailContact: json['email_contact'] as String?,
      telephone: json['telephone'] as String?,
      logoUrl: json['logo_url'] as String?,
      statutActif: json['statut_actif'] as bool? ?? true,
      budget: (json['budget'] as num?)?.toDouble(),
      budgetUtilise: (json['budget_utilise'] as num?)?.toDouble(),
      dateInscription: json['date_inscription'] != null
          ? DateTime.tryParse(json['date_inscription'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_commune': id,
        'nom_commune': nomCommune,
        'departement': departement,
        'region': region,
        'population': population,
        'email_contact': emailContact,
        'telephone': telephone,
        'logo_url': logoUrl,
        'statut_actif': statutActif,
        'budget': budget,
        'budget_utilise': budgetUtilise,
        'date_inscription': dateInscription?.toIso8601String(),
      };

  @override
  String toString() => 'CommuneModel($nomCommune, $region)';
}
