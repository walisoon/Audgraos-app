import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKey = 'logged_user';
  
  // Stream simulado para monitorar mudanças no estado de autenticação
  static Stream<User?> get authStateChanges => Stream.value(_currentUser);
  
  // Usuário atual simulado
  static User? _currentUser;
  static User? get currentUser => _currentUser;

  // Login com Google (simulado)
  static Future<User?> signInWithGoogle() async {
    try {
      // Simular delay de autenticação
      await Future.delayed(const Duration(seconds: 2));
      
      // Criar usuário simulado do Google
      _currentUser = User(
        uid: 'google_${DateTime.now().millisecondsSinceEpoch}',
        email: 'usuario@gmail.com',
        displayName: 'Usuário Google',
        photoURL: 'https://picsum.photos/seed/user123/100/100',
        emailVerified: true,
      );
      
      // Salvar no storage
      await _saveUserToStorage(_currentUser!);
      
      return _currentUser;
    } catch (e) {
      debugPrint('Erro no login com Google: $e');
      return null;
    }
  }

  // Usuários pré-cadastrados para teste
  static const Map<String, String> _predefinedUsers = {
    'admin@audgraos.com': 'admin1894',
    'usuario@audgraos.com': 'user1894',
  };

  // Login com email e senha (simulado)
  static Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Simular delay de autenticação
      await Future.delayed(const Duration(seconds: 1));
      
      // Validação simples
      if (email.isEmpty || password.isEmpty) {
        return null;
      }
      
      if (!email.contains('@')) {
        return null;
      }
      
      // Verificar se é um usuário pré-cadastrado
      if (_predefinedUsers.containsKey(email)) {
        if (_predefinedUsers[email] != password) {
          return null; // Senha incorreta
        }
        
        // Criar usuário simulado para usuário pré-cadastrado
        _currentUser = User(
          uid: 'audgraos_${email.split('@')[0]}',
          email: email,
          displayName: email == 'admin@audgraos.com' ? 'Administrador' : 'Usuário Audgraos',
          photoURL: email == 'admin@audgraos.com' 
            ? 'https://picsum.photos/seed/admin/100/100'
            : 'https://picsum.photos/seed/usuario/100/100',
          emailVerified: true,
        );
        
        // Salvar no storage
        await _saveUserToStorage(_currentUser!);
        
        return _currentUser;
      } else {
        // Rejeitar qualquer outro email que não seja pré-cadastrado
        return null;
      }
    } catch (e) {
      debugPrint('Erro no login com email: $e');
      return null;
    }
  }

  // Registro com email e senha (desabilitado - apenas usuários pré-cadastrados)
  static Future<User?> signUpWithEmail(String email, String password) async {
    // Registro desabilitado - apenas usuários pré-cadastrados podem acessar
    return null;
  }

  // Logout
  static Future<void> signOut() async {
    try {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Erro no logout: $e');
    }
  }

  // Resetar senha (simulado)
  static Future<void> resetPassword(String email) async {
    try {
      // Simular envio de email
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Email de redefinição enviado para: $email');
    } catch (e) {
      debugPrint('Erro ao resetar senha: $e');
    }
  }

  // Verificar se o email está verificado
  static bool isEmailVerified() {
    return _currentUser?.emailVerified ?? false;
  }

  // Enviar verificação de email (simulado)
  static Future<void> sendEmailVerification() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      debugPrint('Email de verificação enviado para: ${_currentUser?.email}');
    } catch (e) {
      debugPrint('Erro ao enviar verificação: $e');
    }
  }

  // Obter informações do usuário
  static Map<String, dynamic> getUserInfo() {
    if (_currentUser == null) return {};

    return {
      'uid': _currentUser!.uid,
      'email': _currentUser!.email,
      'displayName': _currentUser!.displayName,
      'photoURL': _currentUser!.photoURL,
      'emailVerified': _currentUser!.emailVerified,
      'creationTime': DateTime.now().toIso8601String(),
      'lastSignInTime': DateTime.now().toIso8601String(),
    };
  }

  // Carregar usuário do storage
  static Future<void> loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        // Simular carregamento do usuário
        _currentUser = User(
          uid: 'loaded_user',
          email: 'usuario@salvo.com',
          displayName: 'Usuário Salvo',
          photoURL: null,
          emailVerified: true,
        );
      }
    } catch (e) {
      debugPrint('Erro ao carregar usuário do storage: $e');
    }
  }

  // Obter usuários pré-cadastrados para demonstração
  static Map<String, String> getPredefinedUsers() {
    return Map.from(_predefinedUsers);
  }

  // Salvar usuário no storage
  static Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, 'user_data_simulated');
    } catch (e) {
      debugPrint('Erro ao salvar usuário no storage: $e');
    }
  }
}

// Classe User simulada
class User {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;

  User({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
  });
}
