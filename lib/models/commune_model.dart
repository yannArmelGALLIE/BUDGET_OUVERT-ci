// lib/models/commune_model.dart

class CommuneModel {
  final String id;
  final String name;
  final String region;
  final double budgetTotal;
  final double budgetConsomme;
  final double tauxExecution;
  final String visionLabel;
  final List<ProjectModel> projets;

  CommuneModel({
    required this.id,
    required this.name,
    required this.region,
    required this.budgetTotal,
    required this.budgetConsomme,
    required this.tauxExecution,
    required this.visionLabel,
    required this.projets,
  });

  double get pourcentageConsommation =>
      budgetTotal > 0 ? (budgetConsomme / budgetTotal) * 100 : 0;

  static CommuneModel sample() => CommuneModel(
        id: 'adjame',
        name: 'Adjamé',
        region: 'Abidjan',
        budgetTotal: 854200000,
        budgetConsomme: 598940000,
        tauxExecution: 60,
        visionLabel: 'Adjamé Vision 2025',
        projets: ProjectModel.samples(),
      );
}

class ProjectModel {
  final String id;
  final String code;
  final String titre;
  final String description;
  final String categorie;
  final String statut; // 'livré', 'en_cours', 'planifié'
  final double financement;
  final double investissementPaye;
  final double progressionGlobale;
  final String localisation;
  final String commune;
  final String dateDebut;
  final String dateFin;
  final List<EtapeModel> etapes;
  final List<AudioModel> audios;
  final String? imageUrl;

  ProjectModel({
    required this.id,
    required this.code,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.statut,
    required this.financement,
    required this.investissementPaye,
    required this.progressionGlobale,
    required this.localisation,
    required this.commune,
    required this.dateDebut,
    required this.dateFin,
    required this.etapes,
    required this.audios,
    this.imageUrl,
  });

  static List<ProjectModel> samples() => [
        ProjectModel(
          id: 'proj001',
          code: '#P02341',
          titre: 'Construction Centre Santé',
          description:
              'Un établissement moderne de soins de proximité pour améliorer l\'accès à la santé dans la commune d\'Adjamé.',
          categorie: 'Santé',
          statut: 'livré',
          financement: 450000000,
          investissementPaye: 450000000,
          progressionGlobale: 100,
          localisation: 'Abidjan, Adjamé Approx.',
          commune: 'Adjamé',
          dateDebut: 'Janvier 2023',
          dateFin: 'Mars 2024',
          etapes: [
            EtapeModel(label: 'Gros œuvre', statut: 'terminé'),
            EtapeModel(label: 'Équipement médical', statut: 'terminé'),
            EtapeModel(label: 'Recrutement du personnel', statut: 'terminé'),
          ],
          audios: [
            AudioModel(langue: 'Dioula', url: 'audio_dioula.mp3'),
            AudioModel(langue: 'Baoulé', url: 'audio_baoule.mp3'),
          ],
        ),
        ProjectModel(
          id: 'proj002',
          code: '#P01872',
          titre: 'Réhabilitation Lycée Classique',
          description: 'Rénovation complète du lycée classique d\'Adjamé.',
          categorie: 'Éducation',
          statut: 'en_cours',
          financement: 280000000,
          investissementPaye: 224000000,
          progressionGlobale: 80,
          localisation: 'Adjamé Centre',
          commune: 'Adjamé',
          dateDebut: 'Mars 2023',
          dateFin: 'Décembre 2024',
          etapes: [
            EtapeModel(label: 'Fondations', statut: 'terminé'),
            EtapeModel(label: 'Structure', statut: 'en_cours'),
          ],
          audios: [],
        ),
        ProjectModel(
          id: 'proj003',
          code: '#P01345',
          titre: 'Voirie Riviera',
          description: 'Aménagement et bitumage des voiries de la Riviera.',
          categorie: 'Infrastructure',
          statut: 'en_cours',
          financement: 180000000,
          investissementPaye: 90000000,
          progressionGlobale: 50,
          localisation: 'Abidjan, Cocody Riviera',
          commune: 'Adjamé',
          dateDebut: 'Juin 2023',
          dateFin: 'Juin 2024',
          etapes: [],
          audios: [],
        ),
        ProjectModel(
          id: 'proj004',
          code: '#P01201',
          titre: 'Espaces Verts',
          description: 'Aménagement de 5 espaces verts dans la commune.',
          categorie: 'Environnement',
          statut: 'planifié',
          financement: 75000000,
          investissementPaye: 0,
          progressionGlobale: 0,
          localisation: 'Adjamé',
          commune: 'Adjamé',
          dateDebut: 'Janvier 2025',
          dateFin: 'Juillet 2025',
          etapes: [],
          audios: [],
        ),
      ];
}

class EtapeModel {
  final String label;
  final String statut; // 'terminé', 'en_cours', 'planifié'

  EtapeModel({required this.label, required this.statut});
}

class AudioModel {
  final String langue;
  final String url;

  AudioModel({required this.langue, required this.url});
}
