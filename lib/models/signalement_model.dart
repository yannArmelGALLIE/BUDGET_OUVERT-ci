// lib/models/signalement_model.dart

enum TypeSignalement { erreur, fraude, doublon, autre }

enum StatutSignalement { ouvert, enCours, resolu, rejete }

class SignalementModel {
  final String id;
  final String transactionId;
  final String citoyenId;
  final String citoyenNom;
  final TypeSignalement type;
  final String commentaire;
  final List<String> preuves; // URLs images / audio / docs
  final StatutSignalement statut;
  final DateTime dateSignalement;
  final DateTime? dateMiseAJour;

  const SignalementModel({
    required this.id,
    required this.transactionId,
    required this.citoyenId,
    required this.citoyenNom,
    required this.type,
    required this.commentaire,
    this.preuves = const [],
    required this.statut,
    required this.dateSignalement,
    this.dateMiseAJour,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    return SignalementModel(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      citoyenId: json['citoyen_id'] as String,
      citoyenNom: json['citoyen_nom'] as String,
      type: TypeSignalement.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TypeSignalement.autre,
      ),
      commentaire: json['commentaire'] as String,
      preuves: (json['preuves'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      statut: StatutSignalement.values.firstWhere(
        (e) => e.name == json['statut'],
        orElse: () => StatutSignalement.ouvert,
      ),
      dateSignalement: DateTime.parse(json['date_signalement'] as String),
      dateMiseAJour: json['date_mise_a_jour'] != null
          ? DateTime.parse(json['date_mise_a_jour'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'transaction_id': transactionId,
        'citoyen_id': citoyenId,
        'citoyen_nom': citoyenNom,
        'type': type.name,
        'commentaire': commentaire,
        'preuves': preuves,
        'statut': statut.name,
        'date_signalement': dateSignalement.toIso8601String(),
        'date_mise_a_jour': dateMiseAJour?.toIso8601String(),
      };

  String get typeLabel {
    switch (type) {
      case TypeSignalement.erreur:
        return 'Erreur';
      case TypeSignalement.fraude:
        return 'Fraude';
      case TypeSignalement.doublon:
        return 'Doublon';
      case TypeSignalement.autre:
        return 'Autre';
    }
  }

  String get statutLabel {
    switch (statut) {
      case StatutSignalement.ouvert:
        return 'Ouvert';
      case StatutSignalement.enCours:
        return 'En cours';
      case StatutSignalement.resolu:
        return 'Résolu';
      case StatutSignalement.rejete:
        return 'Rejeté';
    }
  }
}
