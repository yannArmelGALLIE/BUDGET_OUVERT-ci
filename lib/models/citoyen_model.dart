// lib/models/citoyen_model.dart
// Aligné sur le MCD : role (CITOYEN | MODERATEUR), statut_compte

class CitoyenModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final String? communeId;
  final String? communeNom;
  final String token;
  final bool notificationActif;
  final String languePreferee;
  final String role; // 'CITOYEN' | 'MODERATEUR'
  final String statutCompte; // 'ACTIF' | 'SUSPENDU' | 'BANNI'

  const CitoyenModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    this.communeId,
    this.communeNom,
    required this.token,
    this.notificationActif = true,
    this.languePreferee = 'fr',
    this.role = 'CITOYEN',
    this.statutCompte = 'ACTIF',
  });

  factory CitoyenModel.fromJson(Map<String, dynamic> json) {
    return CitoyenModel(
      id: json['id_citoyen'] as String? ?? json['id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String?,
      communeId: json['id_commune'] as String? ?? json['commune_id'] as String?,
      communeNom: json['commune_nom'] as String?,
      token: json['token'] as String? ??
          json['id_citoyen'] as String? ??
          json['id'] as String? ??
          '',
      notificationActif: json['notification_actif'] as bool? ?? true,
      languePreferee: json['langue_preferee'] as String? ?? 'fr',
      role: json['role'] as String? ?? 'CITOYEN',
      statutCompte: json['statut_compte'] as String? ?? 'ACTIF',
    );
  }

  Map<String, dynamic> toJson() => {
        'id_citoyen': id,
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'telephone': telephone,
        'id_commune': communeId,
        'commune_nom': communeNom,
        'token': token,
        'notification_actif': notificationActif,
        'langue_preferee': languePreferee,
        'role': role,
        'statut_compte': statutCompte,
      };

  String get nomComplet => '$prenom $nom';
  bool get isActif => statutCompte == 'ACTIF';
  bool get isModo => role == 'MODERATEUR';
}
