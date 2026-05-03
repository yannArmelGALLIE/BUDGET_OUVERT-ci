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

  // ── Commune par défaut : Cocody ──────────────────────────────
  static CommuneModel cocody() => CommuneModel(
        id: 'cocody',
        name: 'Cocody',
        region: 'Abidjan',
        budgetTotal: 0,       // sera écrasé par les données blockchain
        budgetConsomme: 0,    // sera calculé depuis les transactions
        tauxExecution: 0,
        visionLabel: 'Commune Cocody',
        projets: [],          // transactions blockchain = projets
      );

  // Alias pour rétro-compatibilité
  static CommuneModel sample() => cocody();
}

// ─── PROJECT MODEL (données mock / QR scan) ───────────────────────────────
class ProjectModel {
  final String id;
  final String code;
  final String titre;
  final String description;
  final String categorie;
  final String statut;
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

  static List<ProjectModel> samples() => [];
}

class EtapeModel {
  final String label;
  final String statut;
  EtapeModel({required this.label, required this.statut});
}

class AudioModel {
  final String langue;
  final String url;
  AudioModel({required this.langue, required this.url});
}
