import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get userId => _user?.uid;

  // Registra un nuovo utente con email e password
  Future<String?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _handleAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return "Si è verificato un errore imprevisto. Riprova.";
    }
  }

  // Effettua il login dell'utente
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _handleAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return "Si è verificato un errore imprevisto. Riprova.";
    }
  }

  // 🔑 NUOVO METODO: Invia email di ripristino password
  Future<String?> resetPassword(String email) async {
    try {
      _setLoading(true);
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      return null;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      return _handleAuthError(e.code);
    } catch (e) {
      _setLoading(false);
      return "Si è verificato un errore imprevisto. Riprova.";
    }
  }

  // Disconnette l'utente dall'applicazione
  Future<void> signOut() async {
    await _auth.signOut();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Mappa i messaggi di errore di Firebase in italiano
  String _handleAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Nessun account trovato con questa email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Credenziali non corrette. Riprova.';
      case 'email-already-in-use':
        return 'Esiste già un account registrato con questa email.';
      case 'invalid-email':
        return 'L\'indirizzo email inserito non è valido.';
      case 'weak-password':
        return 'La password deve contenere almeno 6 caratteri.';
      default:
        return 'Errore di autenticazione ($errorCode). Riprova.';
    }
  }
}