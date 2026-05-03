// lib/services/session_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Clés de stockage
class _Keys {
  static const isLoggedIn = 'session_is_logged_in';
  static const userNom = 'session_user_nom';
  static const userPrenom = 'session_user_prenom';
  static const userPhone = 'session_user_telephone';
  static const userCni = 'session_user_cni';
  static const userCommune = 'session_user_commune';
  static const authToken = 'session_auth_token';
  static const navIndex = 'session_nav_index';
  static const scanHistory = 'session_scan_history';
  static const onboardingSeen = 'onboarding_seen';
}

/// Service de persistance de session.
/// Sauvegarde et restaure l'état utilisateur entre les relances de l'app.
class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// À appeler dans main() avant runApp().
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ── SESSION AUTH ───────────────────────────────────────────────

  /// Retourne true si une session utilisateur est déjà sauvegardée.
  bool get isLoggedIn => _prefs.getBool(_Keys.isLoggedIn) ?? false;

  /// Token JWT sauvegardé (pour les requêtes API).
  String? get authToken => _prefs.getString(_Keys.authToken);

  // ── ONBOARDING ─────────────────────────────────────────────────

  /// Retourne true si l'utilisateur a déjà vu l'onboarding.
  bool get hasSeenOnboarding => _prefs.getBool(_Keys.onboardingSeen) ?? false;

  /// Marque l'onboarding comme vu — à appeler depuis OnboardingScreen.
  Future<void> markOnboardingSeen() =>
      _prefs.setBool(_Keys.onboardingSeen, true);

  /// Sauvegarde la session après connexion/inscription réussie.
  Future<void> saveSession({
    required UserModel user,
    String? token,
  }) async {
    await Future.wait([
      _prefs.setBool(_Keys.isLoggedIn, true),
      _prefs.setString(_Keys.userNom, user.nom),
      _prefs.setString(_Keys.userPrenom, user.prenom),
      _prefs.setString(_Keys.userPhone, user.telephone),
      _prefs.setString(_Keys.userCni, user.numeroCni),
      _prefs.setString(_Keys.userCommune, user.commune),
      if (token != null) _prefs.setString(_Keys.authToken, token),
    ]);
  }

  /// Charge l'utilisateur depuis le stockage local.
  UserModel? loadUser() {
    if (!isLoggedIn) return null;
    final nom = _prefs.getString(_Keys.userNom);
    final prenom = _prefs.getString(_Keys.userPrenom);
    final phone = _prefs.getString(_Keys.userPhone);
    final cni = _prefs.getString(_Keys.userCni);
    final commune = _prefs.getString(_Keys.userCommune);

    if (nom == null || prenom == null || phone == null) return null;

    return UserModel(
      nom: nom,
      prenom: prenom,
      telephone: phone,
      numeroCni: cni ?? '',
      commune: commune ?? '',
    );
  }

  /// Efface la session (déconnexion).
  Future<void> clearSession() async {
    await Future.wait([
      _prefs.remove(_Keys.isLoggedIn),
      _prefs.remove(_Keys.userNom),
      _prefs.remove(_Keys.userPrenom),
      _prefs.remove(_Keys.userPhone),
      _prefs.remove(_Keys.userCni),
      _prefs.remove(_Keys.userCommune),
      _prefs.remove(_Keys.authToken),
    ]);
  }

  // ── NAVIGATION ─────────────────────────────────────────────────

  /// Sauvegarde le dernier onglet actif.
  Future<void> saveNavIndex(int index) => _prefs.setInt(_Keys.navIndex, index);

  /// Restaure le dernier onglet actif (défaut : 0 = Accueil).
  int get savedNavIndex => _prefs.getInt(_Keys.navIndex) ?? 0;

  // ── HISTORIQUE SCANS ───────────────────────────────────────────

  /// Sauvegarde l'historique des scans QR (max 20 entrées).
  Future<void> saveScanHistory(List<ScanHistoryModel> history) async {
    final limited = history.take(20).toList();
    final encoded = limited
        .map((s) => '${s.id}|${s.projetTitre}|${s.localisation}|${s.date}')
        .toList();
    await _prefs.setStringList(_Keys.scanHistory, encoded);
  }

  /// Charge l'historique des scans sauvegardé.
  List<ScanHistoryModel> loadScanHistory() {
    final raw = _prefs.getStringList(_Keys.scanHistory) ?? [];
    return raw
        .map((entry) {
          final parts = entry.split('|');
          if (parts.length < 4) return null;
          return ScanHistoryModel(
            id: parts[0],
            projetTitre: parts[1],
            localisation: parts[2],
            date: parts[3],
          );
        })
        .whereType<ScanHistoryModel>()
        .toList();
  }
}
