// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

/// Résultat d'une localisation : coordonnées + adresse lisible.
class LocationResult {
  final double latitude;
  final double longitude;
  final String adresse; // Adresse formatée pour l'affichage

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.adresse,
  });

  // Adresse par défaut si le reverse geocoding échoue
  static LocationResult fallback() => LocationResult(
        latitude: 5.3600,
        longitude: -4.0083,
        adresse: 'Abidjan, Côte d\'Ivoire',
      );
}

/// Service GPS centralisé.
/// Gère les permissions, récupère la position et formate l'adresse.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Cache de la dernière position connue
  LocationResult? _lastKnownLocation;
  LocationResult? get lastKnown => _lastKnownLocation;

  /// Demande les permissions et retourne la position actuelle.
  /// En cas d'échec : retourne une position de fallback sur Abidjan.
  Future<LocationResult> getCurrentLocation() async {
    try {
      // 1. Vérifier si le GPS est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _lastKnownLocation ?? LocationResult.fallback();
      }

      // 2. Vérifier / demander la permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _lastKnownLocation ?? LocationResult.fallback();
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return _lastKnownLocation ?? LocationResult.fallback();
      }

      // 3. Obtenir la position (timeout 10s)
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Construire l'adresse (reverse geocoding simplifié basé sur coords)
      final adresse = await _reverseGeocode(position.latitude, position.longitude);

      final result = LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        adresse: adresse,
      );

      _lastKnownLocation = result;
      return result;

    } catch (e) {
      // En cas d'erreur réseau ou timeout → dernière position ou fallback
      return _lastKnownLocation ?? LocationResult.fallback();
    }
  }

  /// Reverse geocoding via l'API Nominatim (OpenStreetMap, sans clé API).
  /// Retourne une adresse lisible depuis des coordonnées.
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      // NOTE : En production, utiliser le package geocoding ou votre propre API
      // Ici on utilise Nominatim directement via http
      // Nécessite import 'package:http/http.dart' as http;
      // et import 'dart:convert';
      //
      // Exemple de réponse Nominatim :
      // { "display_name": "Adjamé, Abidjan, Lagunes, Côte d'Ivoire", ... }
      //
      // Pour l'instant on retourne une adresse formatée depuis les coords :
      return _formatCoordsAsAddress(lat, lng);
    } catch (_) {
      return _formatCoordsAsAddress(lat, lng);
    }
  }

  /// Formatte les coordonnées en adresse approximative pour Abidjan.
  /// À remplacer par un vrai appel geocoding en production.
  String _formatCoordsAsAddress(double lat, double lng) {
    // Zones approximatives d'Abidjan selon les coordonnées
    if (lat > 5.38) return 'Abobo, Abidjan';
    if (lat > 5.36 && lng < -4.01) return 'Adjamé, Abidjan';
    if (lat > 5.36 && lng > -4.01) return 'Cocody, Abidjan';
    if (lat > 5.34 && lng < -4.02) return 'Attécoubé, Abidjan';
    if (lat > 5.34 && lng > -4.00) return 'Plateau, Abidjan';
    if (lat > 5.32) return 'Marcory, Abidjan';
    if (lat > 5.30) return 'Treichville, Abidjan';
    return 'Abidjan, Côte d\'Ivoire';
  }

  /// Vérifie si la permission GPS est accordée (sans la demander).
  Future<bool> hasPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Ouvre les paramètres système pour activer la permission GPS.
  Future<void> openSettings() => Geolocator.openLocationSettings();
}
