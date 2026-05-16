// lib/services/firestore_service.dart
//
//   creerSignalement(transactionId, type, commentaire, preuves) → SignalementModel
//   mesSignalements()                                           → List<SignalementModel>
//   signalementsDeLaTransaction(txId)                          → List<SignalementModel>
//
// Structure Firestore :
//   Collection : signalements
//   Document   : {id auto-généré}
//     transactionId    String
//     citoyenId        String  (UID Firebase)
//     citoyenNom       String
//     type             String  (erreur | fraude | doublon | autre)
//     commentaire      String
//     preuves          List<String>  (URLs Firebase Storage)
//     statut           String  (ouvert par défaut)
//     dateSignalement  Timestamp
//     dateMiseAJour    Timestamp?
//
// pubspec.yaml :
//   cloud_firestore: ^5.x  (déjà ajouté en Phase 1)
//   firebase_storage: ^12.x  (nouveau en Phase 3)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/signalement_model.dart';
import 'firebase_auth_service.dart';

class FirestoreService {
  FirestoreService._();

  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference get _col => _db.collection('signalements');

  // ─── CRÉER UN SIGNALEMENT ─────────────────────────────────────────────────
  static Future<SignalementModel> creerSignalement({
    required String transactionId,
    required TypeSignalement type,
    required String commentaire,
    List<File> preuves = const [],
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Non connecté — impossible de signaler.');

    final citoyen = FirebaseAuthService.currentCitoyen;
    final citoyenNom = citoyen != null
        ? '${citoyen.prenom} ${citoyen.nom}'.trim()
        : 'Citoyen';

    try {
      // 1. Upload des preuves vers Firebase Storage
      final List<String> preuvesUrls = [];
      for (final fichier in preuves) {
        final url = await _uploadFichier(fichier, uid);
        preuvesUrls.add(url);
      }

      // 2. Écriture du signalement dans Firestore
      final docRef = await _col.add({
        'transactionId': transactionId,
        'citoyenId': uid,
        'citoyenNom': citoyenNom,
        'type': type.name,
        'commentaire': commentaire,
        'preuves': preuvesUrls,
        'statut': 'ouvert',
        'dateSignalement': FieldValue.serverTimestamp(),
        'dateMiseAJour': null,
      });

      // 3. Relire le document créé (pour avoir le timestamp serveur)
      final snap = await docRef.get();
      return _fromFirestore(snap);
    } catch (e) {
      if (kDebugMode) print('FirestoreService.creerSignalement: $e');
      rethrow;
    }
  }

  // ─── SIGNALEMENTS DU CITOYEN CONNECTÉ ────────────────────────────────────
  static Future<List<SignalementModel>> mesSignalements() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    try {
      final query = await _col
          .where('citoyenId', isEqualTo: uid)
          .orderBy('dateSignalement', descending: true)
          .get();

      return query.docs.map(_fromFirestore).toList();
    } catch (e) {
      if (kDebugMode) print('FirestoreService.mesSignalements: $e');
      rethrow;
    }
  }

  // ─── SIGNALEMENTS D'UNE TRANSACTION (lecture publique) ───────────────────
  static Future<List<SignalementModel>> signalementsDeLaTransaction(
    String transactionId,
  ) async {
    try {
      final query = await _col
          .where('transactionId', isEqualTo: transactionId)
          .orderBy('dateSignalement', descending: true)
          .get();

      return query.docs.map(_fromFirestore).toList();
    } catch (e) {
      if (kDebugMode) print('FirestoreService.signalementsDeLaTransaction: $e');
      rethrow;
    }
  }

  // ─── UPLOAD FIREBASE STORAGE ──────────────────────────────────────────────
  // Chemin : signalements/{uid}/{timestamp}_{filename}
  static Future<String> _uploadFichier(File fichier, String uid) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${fichier.uri.pathSegments.last}';
    final ref = _storage.ref('signalements/$uid/$fileName');

    final task = await ref.putFile(fichier);
    return await task.ref.getDownloadURL();
  }

  // ─── Firestore DocumentSnapshot → SignalementModel ────────────────────────
  static SignalementModel _fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;

    final dateSignalement = d['dateSignalement'] is Timestamp
        ? (d['dateSignalement'] as Timestamp).toDate()
        : DateTime.now();

    final dateMiseAJour = d['dateMiseAJour'] is Timestamp
        ? (d['dateMiseAJour'] as Timestamp).toDate()
        : null;

    return SignalementModel(
      id: doc.id,
      transactionId: d['transactionId'] as String? ?? '',
      citoyenId: d['citoyenId'] as String? ?? '',
      citoyenNom: d['citoyenNom'] as String? ?? 'Inconnu',
      type: TypeSignalement.values.firstWhere(
        (e) => e.name == d['type'],
        orElse: () => TypeSignalement.autre,
      ),
      commentaire: d['commentaire'] as String? ?? '',
      preuves: (d['preuves'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      statut: StatutSignalement.values.firstWhere(
        (e) => e.name == d['statut'],
        orElse: () => StatutSignalement.ouvert,
      ),
      dateSignalement: dateSignalement,
      dateMiseAJour: dateMiseAJour,
    );
  }
}
