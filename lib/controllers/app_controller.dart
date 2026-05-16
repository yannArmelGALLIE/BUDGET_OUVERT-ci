// lib/controllers/app_controller.dart
import 'package:flutter/material.dart';
import '../models/commune_model.dart';
import '../services/session_service.dart';

class AppController extends ChangeNotifier {
  String? _selectedCommuneId;
  String? get selectedCommune => _selectedCommuneId;

  /// Appelé quand l'utilisateur choisit une commune depuis la liste.
  /// Sauvegarde l'objet complet pour que SessionService.commune soit disponible.
  Future<void> setSelectedCommune(String communeId,
      {CommuneModel? commune}) async {
    _selectedCommuneId = communeId;
    if (commune != null) {
      await SessionService.instance.saveCommune(commune);
    }
    notifyListeners();
  }

  void onAuthChanged() {
    notifyListeners();
  }

  void restoreSelectedCommune() {
    _selectedCommuneId = SessionService.instance.loadSelectedCommune();
    notifyListeners();
  }
}
