// lib/services/api_service.dart
//
// ╔══════════════════════════════════════════════════════════════════╗
// ║  SERVICE API BUDGETOUVERT                                        ║
// ║                                                                  ║
// ║  Chaque méthode existe en DEUX versions :                       ║
// ║    • _mock*()  → réponse simulée (données locales)              ║
// ║    • _real*()  → vrai appel HTTP vers l'API                     ║
// ║                                                                  ║
// ║  Pour passer en production :                                     ║
// ║    Changer  _useMock = true  →  _useMock = false                ║
// ║    ET renseigner  baseUrl   avec l'URL de votre API             ║
// ╚══════════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/commune_model.dart';
import '../models/signal_model.dart';

// ─── CONFIGURATION ────────────────────────────────────────────────────────
class ApiConfig {
  // ⬇ Passer à false quand l'API est prête
  static const bool useMock = true;

  // ⬇ Remplacer par l'URL réelle de l'API
  static const String baseUrl = 'https://api.budgetouvert.gouv.ci/v1';

  // Timeout réseau
  static const Duration timeout = Duration(seconds: 15);

  // Headers communs
  static Map<String, String> headers({String? token}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}

// ─── EXCEPTIONS ───────────────────────────────────────────────────────────
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException({this.statusCode, required this.message});

  @override
  String toString() =>
      'ApiException(${statusCode ?? '?'}): $message';
}

// ─── SERVICE PRINCIPAL ────────────────────────────────────────────────────
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _authToken;
  String? get currentToken => _authToken;
  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  // ════════════════════════════════════════════════════════════════
  //  AUTH
  // ════════════════════════════════════════════════════════════════

  /// Envoie un OTP au numéro de téléphone.
  Future<bool> sendOtp(String telephone) {
    return ApiConfig.useMock
        ? _mockSendOtp(telephone)
        : _realSendOtp(telephone);
  }

  // MOCK ─────────────────────────────────────────────────────────
  Future<bool> _mockSendOtp(String telephone) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // Simule succès
    return true;
  }

  // RÉEL ─────────────────────────────────────────────────────────
  Future<bool> _realSendOtp(String telephone) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/send-otp'),
          headers: ApiConfig.headers(),
          body: jsonEncode({'telephone': telephone}),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) return true;
    final body = jsonDecode(response.body);
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Erreur envoi OTP',
    );
  }

  // ─────────────────────────────────────────────────────────────

  /// Vérifie le code OTP. Retourne le token JWT si valide.
  Future<String?> verifyOtp(String telephone, String code) {
    return ApiConfig.useMock
        ? _mockVerifyOtp(telephone, code)
        : _realVerifyOtp(telephone, code);
  }

  Future<String?> _mockVerifyOtp(String telephone, String code) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // NOTE : la validation réelle est laissée intacte dans AuthController
    // Ici on retourne un token fictif pour l'architecture
    return 'mock_jwt_token_${telephone}_$code';
  }

  Future<String?> _realVerifyOtp(String telephone, String code) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/verify-otp'),
          headers: ApiConfig.headers(),
          body: jsonEncode({'telephone': telephone, 'code': code}),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['token'] as String?;
    }
    final body = jsonDecode(response.body);
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Code invalide',
    );
  }

  // ─────────────────────────────────────────────────────────────

  /// Inscrit un nouvel utilisateur citoyen.
  Future<UserModel?> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String cni,
    required String commune,
  }) {
    return ApiConfig.useMock
        ? _mockRegister(
            nom: nom, prenom: prenom, telephone: telephone,
            cni: cni, commune: commune)
        : _realRegister(
            nom: nom, prenom: prenom, telephone: telephone,
            cni: cni, commune: commune);
  }

  Future<UserModel?> _mockRegister({
    required String nom, required String prenom,
    required String telephone, required String cni,
    required String commune,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return UserModel(
      nom: nom, prenom: prenom, telephone: telephone,
      numeroCni: cni, commune: commune,
    );
  }

  Future<UserModel?> _realRegister({
    required String nom, required String prenom,
    required String telephone, required String cni,
    required String commune,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: ApiConfig.headers(),
          body: jsonEncode({
            'nom': nom, 'prenom': prenom, 'telephone': telephone,
            'numero_cni': cni, 'commune': commune,
          }),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      _authToken = body['token'];
      return UserModel(
        nom: body['nom'], prenom: body['prenom'],
        telephone: body['telephone'], numeroCni: body['numero_cni'],
        commune: body['commune'],
      );
    }
    final body = jsonDecode(response.body);
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Erreur inscription',
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  COMMUNES
  // ════════════════════════════════════════════════════════════════

  /// Récupère le détail d'une commune avec ses projets.
  Future<CommuneModel> getCommune(String communeId) {
    return ApiConfig.useMock
        ? _mockGetCommune(communeId)
        : _realGetCommune(communeId);
  }

  Future<CommuneModel> _mockGetCommune(String communeId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return CommuneModel.sample();
  }

  Future<CommuneModel> _realGetCommune(String communeId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/communes/$communeId'),
          headers: ApiConfig.headers(token: _authToken),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return _parseCommuneFromJson(body);
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Commune introuvable',
    );
  }

  /// Liste toutes les communes disponibles.
  Future<List<CommuneModel>> listCommunes() {
    return ApiConfig.useMock
        ? _mockListCommunes()
        : _realListCommunes();
  }

  Future<List<CommuneModel>> _mockListCommunes() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return [CommuneModel.sample()];
  }

  Future<List<CommuneModel>> _realListCommunes() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/communes'),
          headers: ApiConfig.headers(token: _authToken),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => _parseCommuneFromJson(json)).toList();
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Erreur chargement communes',
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PROJETS
  // ════════════════════════════════════════════════════════════════

  /// Récupère le détail d'un projet par son ID (ou via QR code).
  Future<ProjectModel> getProject(String projectId) {
    return ApiConfig.useMock
        ? _mockGetProject(projectId)
        : _realGetProject(projectId);
  }

  Future<ProjectModel> _mockGetProject(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ProjectModel.samples()
        .firstWhere((p) => p.id == projectId,
            orElse: () => ProjectModel.samples().first);
  }

  Future<ProjectModel> _realGetProject(String projectId) async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/projets/$projectId'),
          headers: ApiConfig.headers(token: _authToken),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      return _parseProjectFromJson(jsonDecode(response.body));
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Projet introuvable',
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  SIGNALEMENTS
  // ════════════════════════════════════════════════════════════════

  /// Récupère les signalements de l'utilisateur connecté.
  Future<List<SignalModel>> getMySignals() {
    return ApiConfig.useMock
        ? _mockGetMySignals()
        : _realGetMySignals();
  }

  Future<List<SignalModel>> _mockGetMySignals() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return SignalModel.samples();
  }

  Future<List<SignalModel>> _realGetMySignals() async {
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/signalements/mes-signalements'),
          headers: ApiConfig.headers(token: _authToken),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => _parseSignalFromJson(json)).toList();
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Erreur chargement signalements',
    );
  }

  /// Soumet un nouveau signalement (avec photo optionnelle).
  Future<SignalModel> submitSignal({
    required String type,
    required String description,
    required String localisation,
    required double latitude,
    required double longitude,
    File? photo,
  }) {
    return ApiConfig.useMock
        ? _mockSubmitSignal(
            type: type, description: description,
            localisation: localisation,
            latitude: latitude, longitude: longitude)
        : _realSubmitSignal(
            type: type, description: description,
            localisation: localisation,
            latitude: latitude, longitude: longitude,
            photo: photo);
  }

  Future<SignalModel> _mockSubmitSignal({
    required String type, required String description,
    required String localisation,
    required double latitude, required double longitude,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return SignalModel(
      id: 'sig_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      localisation: localisation,
      description: description,
      statut: 'nouveau',
      date: "Aujourd'hui",
    );
  }

  Future<SignalModel> _realSubmitSignal({
    required String type, required String description,
    required String localisation,
    required double latitude, required double longitude,
    File? photo,
  }) async {
    // Multipart si photo présente
    if (photo != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/signalements'),
      )
        ..headers.addAll(ApiConfig.headers(token: _authToken))
        ..fields['type'] = type
        ..fields['description'] = description
        ..fields['localisation'] = localisation
        ..fields['latitude'] = latitude.toString()
        ..fields['longitude'] = longitude.toString()
        ..files.add(await http.MultipartFile.fromPath('photo', photo.path));

      final streamed = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return _parseSignalFromJson(jsonDecode(response.body));
      }
      throw ApiException(statusCode: response.statusCode, message: 'Erreur envoi signalement');
    }

    // Sans photo
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/signalements'),
          headers: ApiConfig.headers(token: _authToken),
          body: jsonEncode({
            'type': type, 'description': description,
            'localisation': localisation,
            'latitude': latitude, 'longitude': longitude,
          }),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      return _parseSignalFromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? 'Erreur envoi signalement',
    );
  }

  // ════════════════════════════════════════════════════════════════
  //  PARSEURS JSON → Modèles
  //  (À adapter selon la structure réelle de votre API)
  // ════════════════════════════════════════════════════════════════

  CommuneModel _parseCommuneFromJson(Map<String, dynamic> json) {
    return CommuneModel(
      id: json['id'] ?? '',
      name: json['nom'] ?? '',
      region: json['region'] ?? '',
      budgetTotal: (json['budget_total'] as num?)?.toDouble() ?? 0,
      budgetConsomme: (json['budget_consomme'] as num?)?.toDouble() ?? 0,
      tauxExecution: (json['taux_execution'] as num?)?.toDouble() ?? 0,
      visionLabel: json['vision_label'] ?? '',
      projets: (json['projets'] as List<dynamic>? ?? [])
          .map((p) => _parseProjectFromJson(p))
          .toList(),
    );
  }

  ProjectModel _parseProjectFromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      categorie: json['categorie'] ?? '',
      statut: json['statut'] ?? '',
      financement: (json['financement'] as num?)?.toDouble() ?? 0,
      investissementPaye: (json['investissement_paye'] as num?)?.toDouble() ?? 0,
      progressionGlobale: (json['progression_globale'] as num?)?.toDouble() ?? 0,
      localisation: json['localisation'] ?? '',
      commune: json['commune'] ?? '',
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      etapes: (json['etapes'] as List<dynamic>? ?? [])
          .map((e) => EtapeModel(
                label: e['label'] ?? '',
                statut: e['statut'] ?? '',
              ))
          .toList(),
      audios: (json['audios'] as List<dynamic>? ?? [])
          .map((a) => AudioModel(
                langue: a['langue'] ?? '',
                url: a['url'] ?? '',
              ))
          .toList(),
      imageUrl: json['image_url'],
    );
  }

  SignalModel _parseSignalFromJson(Map<String, dynamic> json) {
    return SignalModel(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      localisation: json['localisation'] ?? '',
      description: json['description'] ?? '',
      statut: json['statut'] ?? 'nouveau',
      date: json['date'] ?? '',
      imageUrl: json['image_url'],
    );
  }
}
