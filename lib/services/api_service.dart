// lib/services/api_service.dart
//

import 'dart:convert';
import 'dart:io';
import '../models/blockchain_model.dart';
import 'package:http/http.dart' as http;
import '../models/commune_model.dart';
import '../models/user_model.dart';

// ─── CONFIGURATION ────────────────────────────────────────────────────────
class ApiConfig {
  // ⬇ Passer à false quand l'API est prête
  /* static const bool useMock = true;

  // ⬇ Remplacer par l'URL réelle de l'API
  static const String baseUrl = 'https://api.budgetouvert.gouv.ci/v1';*/

  static const bool useMock = false;
  static const String baseUrl =
      'https://budgetouvert-ci-production.up.railway.app/api/budget';
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
  String toString() => 'ApiException(${statusCode ?? '?'}): $message';
}

// ─── SERVICE PRINCIPAL ────────────────────────────────────────────────────
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _authToken;
  String? get currentToken => _authToken;
  void setToken(String token) => _authToken = token;
  void clearToken() => _authToken = null;

  static const Map<String, String> _communeNames = {
    'adjame': 'Commune Adjamé',
    'abobo': 'Commune Abobo',
    'cocody': 'Commune Cocody',
    'yopougon': 'Commune Yopougon',
    'marcory': 'Commune Marcory',
    'plateau': 'Commune Plateau',
    'treichville': 'Commune Treichville',
    'koumassi': 'Commune Koumassi',
    'attiecoube': 'Commune Attécoubé',
    'port-bouet': 'Commune Port-Bouët',
  };

  String _toContractName(String key) {
    final lower = key.toLowerCase();
    if (_communeNames.containsKey(lower)) return _communeNames[lower]!;
    if (!key.startsWith('Commune ')) return 'Commune $key';
    return key;
  }
  // ════════════════════════════════════════════════════════════════
  //  AUTH
  // ════════════════════════════════════════════════════════════════

  /// Envoie un OTP au numéro de téléphone.
  Future<bool> sendOtp(String telephone) {
    return ApiConfig.useMock
        ? _mockSendOtp(telephone)
        : _realSendOtp(telephone);
  }

  // Solde live d'une commune depuis la blockchain

// Transactions blockchain d'une commune
  Future<List<BlockchainTxModel>> getTransactions(String communeName) async {
    final uri = Uri.parse(
        '$ApiConfig.baseUrl/transactions/${Uri.encodeComponent(communeName)}');
    final res = await http.get(uri).timeout(ApiConfig.timeout);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['transactions'] as List)
          .map((t) => BlockchainTxModel.fromJson(t))
          .toList();
    }
    throw ApiException(
        statusCode: res.statusCode, message: 'Transactions indisponibles');
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
            nom: nom,
            prenom: prenom,
            telephone: telephone,
            cni: cni,
            commune: commune)
        : _realRegister(
            nom: nom,
            prenom: prenom,
            telephone: telephone,
            cni: cni,
            commune: commune);
  }

  Future<UserModel?> _mockRegister({
    required String nom,
    required String prenom,
    required String telephone,
    required String cni,
    required String commune,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return UserModel(
      nom: nom,
      prenom: prenom,
      telephone: telephone,
      numeroCni: cni,
      commune: commune,
    );
  }

  Future<UserModel?> _realRegister({
    required String nom,
    required String prenom,
    required String telephone,
    required String cni,
    required String commune,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/auth/register'),
          headers: ApiConfig.headers(),
          body: jsonEncode({
            'nom': nom,
            'prenom': prenom,
            'telephone': telephone,
            'numero_cni': cni,
            'commune': commune,
          }),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      _authToken = body['token'];
      return UserModel(
        nom: body['nom'],
        prenom: body['prenom'],
        telephone: body['telephone'],
        numeroCni: body['numero_cni'],
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
    return ApiConfig.useMock ? _mockListCommunes() : _realListCommunes();
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
  //  BLOCKCHAIN — balance & transactions (Railway)
  // ════════════════════════════════════════════════════════════════

  Future<CommuneBalanceModel> getCommuneBalance(String communeKey) async {
    final name = Uri.encodeComponent(_toContractName(communeKey));
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/balance/$name'),
          headers: ApiConfig.headers(token: _authToken),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      // Debug
      print(response.body);
      CommuneBalanceModel r =
          CommuneBalanceModel.fromJson(jsonDecode(response.body));

      return r;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Solde indisponible',
    );
  }

  Future<List<BlockchainTxModel>> getCommuneTransactions(
      String communeKey) async {
    final name = Uri.encodeComponent(_toContractName(communeKey));
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/transactions/$name'),
          headers: ApiConfig.headers(token: _authToken),
        )
        .timeout(ApiConfig.timeout);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      final list = body as List<dynamic>? ?? [];

      // Debug
      List<BlockchainTxModel> r = [];

      final model = list
          .map((t) => BlockchainTxModel.fromJson(t as Map<String, dynamic>))
          .toList();

      return model;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'Transactions indisponibles',
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
    return ProjectModel.samples().firstWhere((p) => p.id == projectId,
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
      investissementPaye:
          (json['investissement_paye'] as num?)?.toDouble() ?? 0,
      progressionGlobale:
          (json['progression_globale'] as num?)?.toDouble() ?? 0,
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
}
