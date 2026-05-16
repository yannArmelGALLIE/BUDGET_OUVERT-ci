// lib/services/firebase_auth_service.dart
//
// Auth citoyen : email + mot de passe (Firebase Auth).
//   init()                              → restaure session au démarrage
//   signUp(prenom, nom, email, mdp)    → CitoyenModel
//   signIn(email, mdp)                 → CitoyenModel
//   signOut()
//   isLoggedIn / currentCitoyen / authHeaders

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/citoyen_model.dart';
import 'firestore_profile_service.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final _auth = FirebaseAuth.instance;

  static CitoyenModel? _currentCitoyen;

  static CitoyenModel? get currentCitoyen => _currentCitoyen;
  static bool get isLoggedIn => _currentCitoyen != null;

  static Future<void> init() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final c = await FirestoreProfileService.lireProfil(user.uid);
      _currentCitoyen = _fusionnerEmailAuth(c, user);
    } catch (e) {
      if (kDebugMode) print('FirebaseAuthService.init: $e');
      // Firestore inaccessible au démarrage — on reconstruit un profil minimal
      // depuis Firebase Auth pour ne pas perdre la session
      _currentCitoyen = CitoyenModel(
        id: user.uid,
        nom: '',
        prenom: user.displayName ?? '',
        email: user.email ?? '${user.uid}@firebase.budgetouvert.ci',
        token: user.uid,
      );
    }
  }

  static CitoyenModel? _fusionnerEmailAuth(CitoyenModel? c, User user) {
    if (c == null) return null;
    final authEmail = user.email;
    if (authEmail == null) return c;
    if (c.email.isNotEmpty && !c.email.endsWith('@firebase.budgetouvert.ci')) {
      return c;
    }
    return CitoyenModel(
      id: c.id,
      nom: c.nom,
      prenom: c.prenom,
      email: authEmail,
      telephone: c.telephone,
      communeId: c.communeId,
      communeNom: c.communeNom,
      token: c.token,
      notificationActif: c.notificationActif,
      languePreferee: c.languePreferee,
      role: c.role,
      statutCompte: c.statutCompte,
    );
  }

  static Future<CitoyenModel> signUp({
    required String prenom,
    required String nom,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      final display = '$prenom $nom'.trim();
      if (display.isNotEmpty) {
        await cred.user?.updateDisplayName(display);
      }

      final citoyen = await FirestoreProfileService.creerProfil(
        uid: uid,
        prenom: prenom,
        nom: nom,
        email: email.trim(),
      );
      _currentCitoyen = citoyen;
      return citoyen;
    } on FirebaseAuthException catch (e) {
      throw Exception(_messageAuth(e));
    }
  }

// APRÈS
  static Future<CitoyenModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = _auth.currentUser!;
      CitoyenModel? citoyen =
          await FirestoreProfileService.lireProfil(user.uid);
      citoyen = _fusionnerEmailAuth(citoyen, user);

      // Crée le profil seulement s'il n'existe vraiment pas dans Firestore
      if (citoyen == null) {
        citoyen = await FirestoreProfileService.creerProfil(
          uid: user.uid,
          prenom: user.displayName?.split(' ').first ?? '',
          nom: user.displayName?.split(' ').skip(1).join(' ') ?? '',
          email: user.email ?? email.trim(),
        );
      }

      _currentCitoyen = citoyen;
      return citoyen;
    } on FirebaseAuthException catch (e) {
      throw Exception(_messageAuth(e));
    } catch (e) {
      // Firestore inaccessible — on reste connecté Firebase mais sans profil complet
      if (kDebugMode) print('FirebaseAuthService.signIn Firestore: $e');
      final user = _auth.currentUser!;
      _currentCitoyen = CitoyenModel(
        id: user.uid,
        nom: '',
        prenom: user.displayName ?? '',
        email: user.email ?? email.trim(),
        token: user.uid,
      );
      return _currentCitoyen!;
    }
  }

  static Future<void> signOut() async {
    _currentCitoyen = null;
    await _auth.signOut();
  }

  static Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        if (_currentCitoyen != null)
          'Authorization': 'Bearer ${_auth.currentUser?.uid ?? ""}',
      };

  static String _messageAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Adresse e-mail invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte pour cet e-mail.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cette adresse e-mail est déjà utilisée.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'operation-not-allowed':
        return 'Connexion par e-mail non activée sur le projet Firebase.';
      default:
        return e.message ?? 'Erreur d\'authentification (${e.code}).';
    }
  }
}
