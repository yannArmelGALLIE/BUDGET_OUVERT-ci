// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import '../models/commune_model.dart';
import '../models/signal_model.dart';

class AppController extends ChangeNotifier {
  // Auth state
  bool _isAuthenticated = false;
  UserModel? _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserModel? get currentUser => _currentUser;

  void login(UserModel user) {
    _currentUser = user;
    _isAuthenticated = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Navigation index
  int _currentNavIndex = 0;
  int get currentNavIndex => _currentNavIndex;

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }
}

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

  Future<bool> sendOtp(String telephone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    _telephone = telephone;
    notifyListeners();
    return true;
  }

  Future<bool> verifyOtp(String code) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    return code == '0000' || code.length == 4;
  }

  Future<bool> register({
    required String nom,
    required String prenom,
    required String telephone,
    required String cni,
    required String commune,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _isLoading = false;
    notifyListeners();
    return true;
  }
}

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
        .where((p) => p.commune == _selectedFilter || p.categorie == _selectedFilter)
        .toList();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadCommune(String id) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _isLoading = false;
    notifyListeners();
  }
}

class SignalController extends ChangeNotifier {
  List<SignalModel> _signals = SignalModel.samples();
  String _selectedType = '';
  String _description = '';
  String _localisation = 'Abidjan, Cocody Riviera 3';
  bool _isSubmitting = false;
  bool _submitted = false;

  List<SignalModel> get signals => _signals;
  String get selectedType => _selectedType;
  String get description => _description;
  String get localisation => _localisation;
  bool get isSubmitting => _isSubmitting;
  bool get submitted => _submitted;

  void setType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  Future<bool> submitSignal() async {
    _isSubmitting = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    final newSignal = SignalModel(
      id: 'sig${DateTime.now().millisecondsSinceEpoch}',
      type: _selectedType,
      localisation: _localisation,
      description: _description,
      statut: 'nouveau',
      date: 'Aujourd\'hui',
    );

    _signals.insert(0, newSignal);
    _isSubmitting = false;
    _submitted = true;
    notifyListeners();
    return true;
  }

  void reset() {
    _selectedType = '';
    _description = '';
    _submitted = false;
    notifyListeners();
  }
}

class ScanController extends ChangeNotifier {
  List<ScanHistoryModel> _history = ScanHistoryModel.samples();
  bool _isScanning = false;
  ProjectModel? _scannedProject;

  List<ScanHistoryModel> get history => _history;
  bool get isScanning => _isScanning;
  ProjectModel? get scannedProject => _scannedProject;

  void startScan() {
    _isScanning = true;
    notifyListeners();
  }

  void stopScan() {
    _isScanning = false;
    notifyListeners();
  }

  Future<ProjectModel?> processQrCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _scannedProject = ProjectModel.samples().first;

    _history.insert(
      0,
      ScanHistoryModel(
        id: 'scan${DateTime.now().millisecondsSinceEpoch}',
        projetTitre: _scannedProject!.titre,
        localisation: _scannedProject!.localisation,
        date: '• Maintenant',
      ),
    );
    notifyListeners();
    return _scannedProject;
  }
}
