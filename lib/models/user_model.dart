// lib/models/signal_model.dart

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
