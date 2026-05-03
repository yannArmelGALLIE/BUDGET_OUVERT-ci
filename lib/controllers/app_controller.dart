// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import '../models/commune_model.dart';
import '../models/user_model.dart';
import '../services/session_service.dart';
import '../services/api_service.dart';

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
