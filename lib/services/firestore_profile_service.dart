// lib/services/firestore_profile_service.dart
//
// Lecture / écriture du profil citoyen dans Firestore.
// Collection : citoyens/{uid}
//
// Structure du document Firestore :
//   prenom            String
//   nom               String
//   email             String
//   telephone         String?
//   communeId         String?
//   role              String   'CITOYEN' | 'MODERATEUR'
//   notificationActif bool
//   languePreferee    String   'fr' par défaut
//   statutCompte      String   'ACTIF' | 'SUSPENDU'
//   dateCreation      Timestamp
//
// pubspec.yaml : cloud_firestore: ^5.x

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/citoyen_model.dart';

class FirestoreProfileService {
  FirestoreProfileService._();

  static final _db = FirebaseFirestore.instance;
  static CollectionReference get _col => _db.collection('citoyens');

  // ─── LIRE le profil citoyen (null si inexistant) ─────────────────────────
  static Future<CitoyenModel?> lireProfil(String uid) async {
    try {
      final doc = await _col.doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()! as Map<String, dynamic>;
      return _fromFirestore(uid, data);
    } catch (e) {
      if (kDebugMode) print('FirestoreProfileService.lireProfil: $e');
      rethrow;
    }
  }

  // ─── CRÉER le profil (première inscription) ───────────────────────────────
  static Future<CitoyenModel> creerProfil({
    required String uid,
    required String prenom,
    required String nom,
    required String email,
    String? telephone,
    String? communeId,
  }) async {
    try {
      final data = {
        'prenom': prenom,
        'nom': nom,
        'email': email,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        'communeId': communeId,
        'role': 'CITOYEN',
        'notificationActif': true,
        'languePreferee': 'fr',
        'statutCompte': 'ACTIF',
        'dateCreation': FieldValue.serverTimestamp(),
      };

      // setOptions merge:false pour ne pas écraser en cas de reconnexion
      await _col.doc(uid).set(data, SetOptions(merge: false));
      return _fromFirestore(uid, data);
    } catch (e) {
      if (kDebugMode) print('FirestoreProfileService.creerProfil: $e');
      rethrow;
    }
  }

  // ─── METTRE À JOUR (communeId, langue, notifications) ────────────────────
  static Future<void> mettreAJour(
    String uid,
    Map<String, dynamic> champs,
  ) async {
    try {
      await _col.doc(uid).update(champs);
    } catch (e) {
      if (kDebugMode) print('FirestoreProfileService.mettreAJour: $e');
      rethrow;
    }
  }

  // ─── Helper : Firestore Map → CitoyenModel ────────────────────────────────
  static CitoyenModel _fromFirestore(String uid, Map<String, dynamic> d) {
    final email = d['email'] as String? ?? '';
    return CitoyenModel(
      id: uid,
      nom: d['nom'] as String? ?? '',
      prenom: d['prenom'] as String? ?? '',
      email: email.isNotEmpty ? email : '$uid@firebase.budgetouvert.ci',
      telephone: d['telephone'] as String?,
      communeId: d['communeId'] as String?,
      communeNom: d['communeNom'] as String?,
      // CitoyenModel.token n'est plus utilisé pour les appels REST avec Firebase.
      // On passe l'UID, suffisant pour authHeaders.
      token: uid,
      notificationActif: d['notificationActif'] as bool? ?? true,
      languePreferee: d['languePreferee'] as String? ?? 'fr',
      role: d['role'] as String? ?? 'CITOYEN',
      statutCompte: d['statutCompte'] as String? ?? 'ACTIF',
    );
  }
}
