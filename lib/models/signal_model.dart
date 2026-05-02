// lib/models/signal_model.dart

class SignalModel {
  final String id;
  final String type; // 'voirie', 'eclairage', 'assainissement', 'dechets', 'autres'
  final String localisation;
  final String description;
  final String statut; // 'en_cours', 'resolu', 'nouveau'
  final String date;
  final String? imageUrl;

  SignalModel({
    required this.id,
    required this.type,
    required this.localisation,
    required this.description,
    required this.statut,
    required this.date,
    this.imageUrl,
  });

  static List<SignalModel> samples() => [
        SignalModel(
          id: 'sig001',
          type: 'eclairage',
          localisation: 'Hôt. • Riviera Palefrique',
          description: 'Éclairage défaillant sur l\'avenue principale.',
          statut: 'en_cours',
          date: '14 Avr 2024',
          imageUrl: null,
        ),
        SignalModel(
          id: 'sig002',
          type: 'voirie',
          localisation: '12 Avr 2024 • Cocody Centre',
          description: 'Nid de poule dangereux devant l\'école.',
          statut: 'resolu',
          date: '12 Avr 2024',
          imageUrl: null,
        ),
      ];
}

class UserModel {
  final String nom;
  final String prenom;
  final String telephone;
  final String numeroCni;
  final String commune;

  UserModel({
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.numeroCni,
    required this.commune,
  });
}

class ScanHistoryModel {
  final String id;
  final String projetTitre;
  final String localisation;
  final String date;

  ScanHistoryModel({
    required this.id,
    required this.projetTitre,
    required this.localisation,
    required this.date,
  });

  static List<ScanHistoryModel> samples() => [
        ScanHistoryModel(
          id: 'scan001',
          projetTitre: 'Pont Alassane Ouattara',
          localisation: 'Cocody, Abidjan',
          date: '• Hier',
        ),
      ];
}
