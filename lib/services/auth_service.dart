import 'dart:convert';
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
        // Verificar nos usuários cadastrados dinamicamente
        final usuariosCadastrados = await carregarUsuarios();
        final usuarioEncontrado = usuariosCadastrados.firstWhere(
          (user) => user['email'] == email && user['senha'] == password,
          orElse: () => {},
        );
        
        if (usuarioEncontrado.isNotEmpty) {
          // Criar usuário simulado para usuário cadastrado
          _currentUser = User(
            uid: 'user_${usuarioEncontrado['email'].toString().split('@')[0]}',
            email: usuarioEncontrado['email'],
            displayName: usuarioEncontrado['nome'] ?? usuarioEncontrado['email'].toString().split('@')[0],
            photoURL: 'https://picsum.photos/seed/${usuarioEncontrado['email']}/100/100',
            emailVerified: true,
          );
          
          // Salvar no storage
          await _saveUserToStorage(_currentUser!);
          
          return _currentUser;
        } else {
          // Rejeitar qualquer outro email que não seja pré-cadastrado ou cadastrado dinamicamente
          return null;
        }
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

  // Migrar usuários antigos para o novo formato
  static Future<void> migrarUsuariosAntigos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuariosJson = prefs.getString('usuarios_cadastrados');
      
      if (usuariosJson != null) {
        try {
          final List<dynamic> usuariosList = jsonDecode(usuariosJson);
          final List<Map<String, dynamic>> usuariosMigrados = [];
          
          for (var item in usuariosList) {
            if (item is Map) {
              final Map<String, dynamic> usuarioFormatado = {};
              item.forEach((key, value) {
                usuarioFormatado[key.toString()] = value.toString();
              });
              usuariosMigrados.add(usuarioFormatado);
            }
          }
          
          // Salvar com novo formato
          final novoJson = jsonEncode(usuariosMigrados);
          await prefs.setString('usuarios_cadastrados', novoJson);
          
          debugPrint('Usuários migrados com sucesso: ${usuariosMigrados.length} usuários');
        } catch (e) {
          debugPrint('Erro ao migrar usuários: $e');
          // Se falhar, limpar tudo
          await prefs.remove('usuarios_cadastrados');
        }
      }
    } catch (e) {
      debugPrint('Erro na migração: $e');
    }
  }

  // Limpar dados corrompidos (função auxiliar)
  static Future<void> limparDadosCorrompidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('usuarios_cadastrados');
      debugPrint('Dados de usuários corrompidos foram limpos');
    } catch (e) {
      debugPrint('Erro ao limpar dados: $e');
    }
  }

  // Carregar usuários cadastrados - abordagem simplificada
  static Future<List<Map<String, dynamic>>> carregarUsuarios() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuariosJson = prefs.getString('usuarios_cadastrados');
      
      if (usuariosJson != null) {
        try {
          final List<dynamic> usuariosList = jsonDecode(usuariosJson);
          final List<Map<String, dynamic>> usuariosFormatados = [];
          
          for (var item in usuariosList) {
            if (item is Map) {
              final Map<String, dynamic> usuarioMap = {};
              item.forEach((key, value) {
                usuarioMap[key.toString()] = value.toString();
              });
              usuariosFormatados.add(usuarioMap);
            }
          }
          
          return usuariosFormatados;
        } catch (e) {
          debugPrint('Erro ao decodificar JSON: $e');
          // Se houver erro, limpar e retornar padrão
          await prefs.remove('usuarios_cadastrados');
        }
      }
      
      // Retornar usuários pré-definidos como padrão
      return _predefinedUsers.entries.map((entry) => {
        'email': entry.key,
        'senha': entry.value,
        'nome': entry.key.split('@')[0],
        'tipo': entry.key == 'admin@audgraos.com' ? 'admin' : 'auditor',
      }).toList();
    } catch (e) {
      debugPrint('Erro ao carregar usuários: $e');
      return [];
    }
  }

  // Adicionar novo usuário - abordagem simplificada
  static Future<void> adicionarUsuario(String email, String senha, String nome, {String tipo = 'auditor'}) async {
    try {
      // Limpar tudo para começar do zero
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('usuarios_cadastrados');
      
      // Carregar apenas usuários padrão
      final usuarios = await carregarUsuarios();
      
      // Verificar se email já existe
      if (usuarios.any((user) => user['email'] == email)) {
        throw Exception('Email já cadastrado');
      }
      
      // Criar lista simples para salvar
      final List<Map<String, String>> listaParaSalvar = [];
      
      // Adicionar usuários padrão primeiro
      for (var usuario in usuarios) {
        listaParaSalvar.add({
          'email': usuario['email'].toString(),
          'senha': usuario['senha'].toString(),
          'nome': usuario['nome'].toString(),
          'tipo': usuario['tipo'].toString(),
        });
      }
      
      // Adicionar novo usuário
      listaParaSalvar.add({
        'email': email,
        'senha': senha,
        'nome': nome,
        'tipo': tipo,
      });
      
      // Salvar como JSON simples
      final usuariosJson = jsonEncode(listaParaSalvar);
      await prefs.setString('usuarios_cadastrados', usuariosJson);
      
      debugPrint('Usuário adicionado com sucesso: $email ($tipo)');
    } catch (e) {
      debugPrint('Erro ao adicionar usuário: $e');
      rethrow;
    }
  }

  // Excluir usuário
  static Future<void> excluirUsuario(String email) async {
    try {
      final usuarios = await carregarUsuarios();
      
      // Remover usuário
      usuarios.removeWhere((user) => user['email'] == email);
      
      // Salvar no storage
      final prefs = await SharedPreferences.getInstance();
      final usuariosJson = jsonEncode(usuarios);
      await prefs.setString('usuarios_cadastrados', usuariosJson);
      
      debugPrint('Usuário excluído: $email');
    } catch (e) {
      debugPrint('Erro ao excluir usuário: $e');
      rethrow;
    }
  }

  // Atualizar usuário existente
  static Future<void> atualizarUsuario(String emailAntigo, Map<String, dynamic> usuarioAtualizado) async {
    try {
      final usuarios = await carregarUsuarios();
      
      // Encontrar o índice do usuário
      final index = usuarios.indexWhere((user) => user['email'] == emailAntigo);
      
      if (index != -1) {
        // Garantir que todos os valores sejam String antes de atualizar
        final usuarioFormatado = usuarioAtualizado.map((key, value) => MapEntry(key, value.toString()));
        
        // Atualizar o usuário
        usuarios[index] = usuarioFormatado;
        
        // Salvar no storage
        final prefs = await SharedPreferences.getInstance();
        final usuariosJson = jsonEncode(usuarios);
        await prefs.setString('usuarios_cadastrados', usuariosJson);
        
        debugPrint('Usuário atualizado: ${usuarioAtualizado['email']}');
      } else {
        throw Exception('Usuário não encontrado');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar usuário: $e');
      rethrow;
    }
  }

  // Verificar se usuário atual é admin
  static bool isCurrentUserAdmin() {
    if (_currentUser == null) return false;
    
    // Admin pré-definido
    if (_currentUser!.email == 'admin@audgraos.com') return true;
    
    // Para usuários dinâmicos, precisaríamos armazenar o tipo no User
    // Por enquanto, vamos verificar pelo email
    return _currentUser!.email?.contains('admin') == true;
  }

  // Obter tipo do usuário atual
  static String getCurrentUserType() {
    if (_currentUser == null) return 'auditor';
    
    if (_currentUser!.email == 'admin@audgraos.com') return 'admin';
    return 'auditor';
  }

  // Verificar permissão para acessar usuários
  static bool podeAcessarUsuarios() {
    return isCurrentUserAdmin();
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
