// lib/controllers/app_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/commune_model.dart';
import '../models/signal_model.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

// ═══════════════════════════════════════════════════════════════════
//  APP CONTROLLER — état global + session persistée
// ═══════════════════════════════════════════════════════════════════

class AppController extends ChangeNotifier {
  // Auth state
  bool _isAuthenticated = false;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;

  /// Restaure la session depuis SharedPreferences au démarrage.
  void restoreSession() {
    final session = SessionService.instance;
    if (session.isLoggedIn) {
      _currentUser = session.loadUser();
      _isAuthenticated = _currentUser != null;
      // Restaurer aussi le dernier onglet actif
      _currentNavIndex = session.savedNavIndex;
    }
    notifyListeners();
  }

  void login(UserModel user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> logout() async {
    await SessionService.instance.clearSession();
    ApiService.instance.clearToken();
    _currentUser = null;
    _isAuthenticated = false;
    _currentNavIndex = 0;
    notifyListeners();
  }

  // Navigation index
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  Future<void> setNavIndex(int index) async {
    _currentNavIndex = index;
    await SessionService.instance.saveNavIndex(index);
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  AUTH CONTROLLER — connexion / inscription via ApiService
// ═══════════════════════════════════════════════════════════════════

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String _telephone = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get telephone => _telephone;

  void setTelephone(String value) {
    _telephone = value;
    _error = null;
    notifyListeners();
  }

  /// Envoie un OTP via ApiService.
  Future<bool> sendOtp(String telephone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final ok = await ApiService.instance.sendOtp(telephone);
      _telephone = telephone;
      return ok;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie l'OTP via ApiService et retourne le token.
  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await ApiService.instance.verifyOtp(_telephone, code);
      if (token != null) {
        ApiService.instance.setToken(token);
        return true;
      }
      _error = 'Code invalide';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Inscrit un nouvel utilisateur via ApiService et persiste la session.
  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String cni,
    required String commune,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await ApiService.instance.register(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        cni: cni,
        commune: commune,
      );
      if (user != null) {
        // Persister la session localement
        await SessionService.instance.saveSession(
          user: user,
          token: ApiService.instance.currentToken,
        );
        return true;
      }
      _error = 'Erreur lors de l\'inscription';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  COMMUNE CONTROLLER — données via ApiService
// ═══════════════════════════════════════════════════════════════════

class CommuneController extends ChangeNotifier {
  CommuneModel _commune = CommuneModel.sample();
  String _selectedFilter = 'Tout';
  bool _isLoading = false;

  CommuneModel get commune => _commune;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;

  List<ProjectModel> get filteredProjets {
    if (_selectedFilter == 'Tout') return _commune.projets;
    return _commune.projets
        .where((p) =>
            p.commune == _selectedFilter || p.categorie == _selectedFilter)
        .toList();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadCommune(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _commune = await ApiService.instance.getCommune(id);
    } catch (_) {
      // En cas d'erreur réseau on garde les données locales
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SIGNAL CONTROLLER — soumission via ApiService + LocationService
// ═══════════════════════════════════════════════════════════════════

class SignalController extends ChangeNotifier {
  List<SignalModel> _signals = SignalModel.samples();
  String _selectedType = '';
  String _description = '';
  String _localisation = 'Abidjan, Côte d\'Ivoire';
  double _latitude = 5.3600;
  double _longitude = -4.0083;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _isFetchingLocation = false;

  List<SignalModel> get signals => _signals;
  String get selectedType => _selectedType;
  String get description => _description;
  String get localisation => _localisation;
  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;
  bool get isFetchingLocation => _isFetchingLocation;

  void setType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  /// Récupère la position GPS réelle via LocationService.
  Future<void> fetchCurrentLocation() async {
    _isFetchingLocation = true;
    notifyListeners();

    final result = await LocationService.instance.getCurrentLocation();
    _localisation = result.adresse;
    _latitude = result.latitude;
    _longitude = result.longitude;

    _isFetchingLocation = false;
    notifyListeners();
  }

  /// Charge les signalements de l'utilisateur depuis l'API.
  Future<void> loadMySignals() async {
    try {
      _signals = await ApiService.instance.getMySignals();
      notifyListeners();
    } catch (_) {
      // Conserver les données locales en cas d'erreur
    }
  }

  Future<bool> submitSignal({File? photo}) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final signal = await ApiService.instance.submitSignal(
        type: _selectedType,
        description: _description,
        localisation: _localisation,
        latitude: _latitude,
        longitude: _longitude,
        photo: photo,
      );

      _signals.insert(0, signal);
      _submitted = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedType = '';
    _description = '';
    _submitted = false;
    notifyListeners();
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCAN CONTROLLER — historique persisté via SessionService
// ═══════════════════════════════════════════════════════════════════

class ScanController extends ChangeNotifier {
  List<ScanHistoryModel> _history = [];
  bool _isScanning = false;
  ProjectModel? _scannedProject;

  List<ScanHistoryModel> get history => _history;
  bool get isScanning => _isScanning;
  ProjectModel? get scannedProject => _scannedProject;

  /// Restaure l'historique persisté au démarrage.
  void restoreHistory() {
    _history = SessionService.instance.loadScanHistory();
    if (_history.isEmpty) {
      _history = ScanHistoryModel.samples();
    }
    notifyListeners();
  }

  void startScan() {
    _isScanning = true;
    notifyListeners();
  }

  void stopScan() {
    _isScanning = false;
    notifyListeners();
  }

  /// Ajoute une entrée à l'historique et persiste (appelé par scan_screen).
  Future<void> addHistoryEntry(ScanHistoryModel entry) async {
    _history.insert(0, entry);
    await SessionService.instance.saveScanHistory(_history);
    notifyListeners();
  }

  /// Traite un QR code scanné — charge le projet via ApiService.
  Future<ProjectModel?> processQrCode(String code) async {
    // Extraire l'ID depuis le format "BUDGETOUVERT:<id>"
    final projectId = code.startsWith('BUDGETOUVERT:')
        ? code.replaceFirst('BUDGETOUVERT:', '')
        : code;

    try {
      _scannedProject = await ApiService.instance.getProject(projectId);
    } catch (_) {
      // Fallback sur les données locales
      _scannedProject = ProjectModel.samples().first;
    }

    // Persister dans l'historique
    final entry = ScanHistoryModel(
      id: 'scan${DateTime.now().millisecondsSinceEpoch}',
      projetTitre: _scannedProject!.titre,
      localisation: _scannedProject!.localisation,
      date: '• Maintenant',
    );

    _history.insert(0, entry);
    await SessionService.instance.saveScanHistory(_history);

    notifyListeners();
    return _scannedProject;
  }
}
