import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseConfig {
  static bool _initialized = false;

  static Future<void> initializeFirebase() async {
    if (!_initialized) {
      try {
        await Firebase.initializeApp();
        _initialized = true;
        debugPrint('Firebase inicializado com sucesso');
      } catch (e) {
        debugPrint('Erro ao inicializar Firebase: $e');
      }
    }
  }

  static Future<void> configureGoogleSignIn() async {
    try {
      // Configurar Google Sign-In para web
      if (UniversalPlatform.isWeb) {
        await GoogleSignIn(
          clientId: 'your-web-client-id.apps.googleusercontent.com',
          serverClientId: 'your-server-client-id.apps.googleusercontent.com',
        );
      }
    } catch (e) {
      debugPrint('Erro ao configurar Google Sign-In: $e');
    }
  }
}

class UniversalPlatform {
  static bool get isWeb => identical(0, 0.0) || identical(0, 0.0) || identical(0, 0.0);
}
