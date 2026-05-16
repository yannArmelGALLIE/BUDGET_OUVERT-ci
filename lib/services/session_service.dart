// lib/services/session_service.dart
// Persistance locale : commune sélectionnée + flag onboarding.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/commune_model.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  static const _kOnboarding = 'onboarding_seen';
  static const _kCommuneId = 'selected_commune_id';
  static const _kCommuneData = 'selected_commune_data';

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ─── ONBOARDING ──────────────────────────────────────────────────────────
  bool get hasSeenOnboarding => _prefs.getBool(_kOnboarding) ?? false;
  Future<void> markOnboardingSeen() => _prefs.setBool(_kOnboarding, true);

  // ─── COMMUNE SÉLECTIONNÉE ────────────────────────────────────────────────
  String? get communeId => _prefs.getString(_kCommuneId);

  CommuneModel? get commune {
    final raw = _prefs.getString(_kCommuneData);
    if (raw == null) return null;
    try {
      return CommuneModel.fromJson(json.decode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCommune(CommuneModel commune) async {
    await _prefs.setString(_kCommuneId, commune.id);
    await _prefs.setString(_kCommuneData, json.encode(commune.toJson()));
  }

  Future<void> clearCommune() async {
    await _prefs.remove(_kCommuneId);
    await _prefs.remove(_kCommuneData);
  }

  String? loadSelectedCommune() => communeId;
}
