import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SupabaseService {
  static const String _supabaseUrl = 'https://oowbeehssifgizhgxgpc.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vd2JlZWhzc2lmZ2l6aGd4Z3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzE0MjYsImV4cCI6MjA5MDkwNzQyNn0.Fqw-Yma5zP0GG1M2BGXDA1benbR84AUnWoiU_FLmyMA';

  static Future<void> initialize() async {
    // Não precisa inicializar nada com HTTP direto
    print('Supabase Service inicializado (HTTP direto)');
  }

  // Headers padrão para requisições
  static Map<String, String> get _headers => {
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  // Tabela de usuários
  static const String _usersTable = 'users';

  // Adicionar usuário
  static Future<void> adicionarUsuario({
    required String email,
    required String senha,
    required String nome,
    required String tipo,
  }) async {
    try {
      // Primeiro, testar se a conexão funciona
      final conexaoOK = await _testarConexao();
      if (!conexaoOK) {
        throw Exception('Sem conexão com o Supabase. Usando modo offline.');
      }

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/$_usersTable'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'senha': senha,
          'nome': nome,
          'tipo': tipo,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Erro ao adicionar usuário: ${response.body}');
      }
    } catch (e) {
      print('Erro completo: $e');
      throw Exception('Erro ao adicionar usuário no Supabase: $e');
    }
  }

  // Testar conexão com Supabase
  static Future<bool> _testarConexao() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_usersTable?select=count&limit=1'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Erro de conexão: $e');
      return false;
    }
  }

  // Carregar todos os usuários
  static Future<List<Map<String, dynamic>>> carregarUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_usersTable'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erro ao carregar usuários: ${response.body}');
      }
    } catch (e) {
      print('Erro ao carregar usuários do Supabase: $e');
      // Se falhar, retornar usuários padrão
      return _getUsuariosPadrao();
    }
  }

  // Excluir usuário
  static Future<void> excluirUsuario(String email) async {
    try {
      final response = await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/$_usersTable?email=eq.$email'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Erro ao excluir usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir usuário no Supabase: $e');
    }
  }

  // Atualizar usuário
  static Future<void> atualizarUsuario(
    String emailAntigo,
    Map<String, dynamic> dadosAtualizados,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/$_usersTable?email=eq.$emailAntigo'),
        headers: _headers,
        body: jsonEncode(dadosAtualizados),
      );

      if (response.statusCode != 204) {
        throw Exception('Erro ao atualizar usuário: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar usuário no Supabase: $e');
    }
  }

  // Verificar se email já existe
  static Future<bool> emailExiste(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_usersTable?email=eq.$email&select=email'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Usuários padrão (fallback)
  static List<Map<String, dynamic>> _getUsuariosPadrao() {
    return [
      {
        'email': 'admin@audgraos.com',
        'senha': 'admin1894',
        'nome': 'Administrador',
        'tipo': 'admin',
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'email': 'usuario@audgraos.com',
        'senha': 'user1894',
        'nome': 'Usuário Audgraos',
        'tipo': 'auditor',
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  // Tabela de laudos
  static const String _laudosTable = 'laudos';

  // Adicionar laudo
  static Future<void> adicionarLaudo(Map<String, dynamic> laudo) async {
    try {
      print('=== SUPABASE: INICIANDO ENVIO ===');
      print('URL completa: $_supabaseUrl/rest/v1/$_laudosTable');
      print('Headers: $_headers');
      print('Dados a enviar: $laudo');
      
      // Validar dados antes de enviar (apenas campos obrigatórios)
      if (laudo['numero_laudo'] == null || laudo['numero_laudo'].toString().trim().isEmpty) {
        print('AVISO: numero_laudo está vazio, gerando um novo...');
        laudo['numero_laudo'] = 'LAU-${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Mapear campos para nomes corretos do banco
      final Map<String, dynamic> dadosMapeados = {};
      
      // Mapear apenas campos que existem na tabela
      if (laudo['id'] != null) dadosMapeados['id'] = laudo['id'];
      if (laudo['numero_laudo'] != null) dadosMapeados['numero_laudo'] = laudo['numero_laudo'];
      if (laudo['servico'] != null) dadosMapeados['servico'] = laudo['servico'];
      if (laudo['data'] != null) dadosMapeados['data'] = laudo['data'];
      if (laudo['status'] != null) dadosMapeados['status'] = laudo['status'];
      if (laudo['origem'] != null) dadosMapeados['origem'] = laudo['origem'];
      if (laudo['destino'] != null) dadosMapeados['destino'] = laudo['destino'];
      if (laudo['notaFiscal'] != null) dadosMapeados['nota_fiscal'] = laudo['notaFiscal'];
      if (laudo['produto'] != null) dadosMapeados['produto'] = laudo['produto'];
      if (laudo['cliente'] != null) dadosMapeados['cliente'] = laudo['cliente'];
      if (laudo['placa'] != null) dadosMapeados['placa'] = laudo['placa'];
      if (laudo['certificadora'] != null) dadosMapeados['certificadora'] = laudo['certificadora'];
      if (laudo['peso'] != null) dadosMapeados['peso'] = laudo['peso'];
      if (laudo['transportadora'] != null) dadosMapeados['transportadora'] = laudo['transportadora'];
      if (laudo['nomeClassificador'] != null) dadosMapeados['nome_classificador'] = laudo['nomeClassificador'];
      if (laudo['tipo'] != null) dadosMapeados['tipo'] = laudo['tipo'];
      if (laudo['terminalRecusa'] != null) dadosMapeados['terminal_recusa'] = laudo['terminalRecusa'];
      if (laudo['resultado'] != null) dadosMapeados['resultado'] = laudo['resultado'];
      if (laudo['odor'] != null) dadosMapeados['odor'] = laudo['odor'];
      if (laudo['sementes'] != null) dadosMapeados['sementes'] = laudo['sementes'];
      if (laudo['observacoes'] != null) dadosMapeados['observacoes'] = laudo['observacoes'];
      if (laudo['umidade'] != null) dadosMapeados['umidade'] = laudo['umidade'];
      if (laudo['materiasEstranhas'] != null) dadosMapeados['materias_estranhas'] = laudo['materiasEstranhas'];
      if (laudo['queimados'] != null) dadosMapeados['queimados'] = laudo['queimados'];
      if (laudo['ardidos'] != null) dadosMapeados['ardidos'] = laudo['ardidos'];
      if (laudo['mofados'] != null) dadosMapeados['mofados'] = laudo['mofados'];
      if (laudo['created_at'] != null) dadosMapeados['created_at'] = laudo['created_at'];
      
      print('Dados mapeados: $dadosMapeados');
      
      // Adicionar header para ignorar cache
      final headersComRefresh = {
        ..._headers,
        'Prefer': 'return=minimal, cache-control=no-cache, no-store',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
      };
      
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable'),
        headers: headersComRefresh,
        body: jsonEncode(dadosMapeados),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout de 30 segundos ao conectar com Supabase');
        },
      );

      print('✅ RESPOSTA RECEBIDA');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body length: ${response.body.length} caracteres');

      if (response.statusCode == 201) {
        print('🎉 SUCESSO TOTAL: Laudo adicionado no Supabase');
      } else if (response.statusCode == 400) {
        // Tentar identificar o erro específico
        if (response.body.contains('nome_classificador')) {
          throw Exception('Erro 400 - Campo nome_classificador não existe na tabela');
        } else if (response.body.contains('certificadora')) {
          throw Exception('Erro 400 - Campo certificadora não existe na tabela');
        } else if (response.body.contains('terminal_recusa')) {
          throw Exception('Erro 400 - Campo terminal_recusa não existe na tabela');
        } else if (response.body.contains('materias_estranhas')) {
          throw Exception('Erro 400 - Campo materias_estranhas não existe na tabela');
        } else {
          throw Exception('Erro 400 - Dados inválidos: ${response.body}');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Erro 401 - Chave API inválida');
      } else if (response.statusCode == 403) {
        throw Exception('Erro 403 - Permissão negada. Verifique RLS policies');
      } else if (response.statusCode == 404) {
        throw Exception('Erro 404 - Tabela "laudos" não encontrada');
      } else if (response.statusCode == 500) {
        throw Exception('Erro 500 - Erro interno do servidor');
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
      
    } catch (e) {
      print('❌ ERRO CAPTURADO EM DETALHES:');
      print('Erro: $e');
      print('Tipo: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      
      // Tentar detectar tipo específico de erro
      if (e.toString().contains('SocketException')) {
        throw Exception('❌ Sem conexão com internet ou servidor inacessível');
      } else if (e.toString().contains('Timeout')) {
        throw Exception('❌ Servidor demorou muito para responder');
      } else if (e.toString().contains('Host')) {
        throw Exception('❌ URL do Supabase incorreta ou servidor offline');
      } else {
        throw Exception('❌ Erro ao adicionar laudo no Supabase: $e');
      }
    }
  }

  // Carregar todos os laudos
  static Future<List<Map<String, dynamic>>> carregarLaudos() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?order=created_at.desc'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Mapear dados para nomes usados no app
        return data.map((laudo) {
          final Map<String, dynamic> laudoMapeado = Map<String, dynamic>.from(laudo);
          
          // Converter nomes do banco para nomes do app
          if (laudo.containsKey('nota_fiscal')) {
            laudoMapeado['notaFiscal'] = laudo['nota_fiscal'];
          }
          if (laudo.containsKey('nome_classificador')) {
            laudoMapeado['nomeClassificador'] = laudo['nome_classificador'];
          }
          if (laudo.containsKey('terminal_recusa')) {
            laudoMapeado['terminalRecusa'] = laudo['terminal_recusa'];
          }
          if (laudo.containsKey('materias_estranhas')) {
            laudoMapeado['materiasEstranhas'] = laudo['materias_estranhas'];
          }
          
          return laudoMapeado;
        }).toList();
      } else {
        throw Exception('Erro ao carregar laudos: ${response.body}');
      }
    } catch (e) {
      print('Erro ao carregar laudos do Supabase: $e');
      return [];
    }
  }

  // Excluir laudo
  static Future<void> excluirLaudo(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?id=eq.$id'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Erro ao excluir laudo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao excluir laudo no Supabase: $e');
    }
  }

  // Atualizar laudo
  static Future<void> atualizarLaudo(String id, Map<String, dynamic> dadosAtualizados) async {
    try {
      final response = await http.patch(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?id=eq.$id'),
        headers: _headers,
        body: jsonEncode(dadosAtualizados),
      );

      if (response.statusCode != 204) {
        throw Exception('Erro ao atualizar laudo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar laudo no Supabase: $e');
    }
  }

  // Verificar se laudo já existe
  static Future<bool> laudoExiste(String numeroLaudo) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?numero_laudo=eq.$numeroLaudo&select=id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Inicializar usuários padrão no Supabase
  static Future<void> inicializarUsuariosPadrao() async {
    try {
      final usuariosPadrao = _getUsuariosPadrao();
      
      for (var usuario in usuariosPadrao) {
        final existe = await emailExiste(usuario['email']);
        if (!existe) {
          await adicionarUsuario(
            email: usuario['email'],
            senha: usuario['senha'],
            nome: usuario['nome'],
            tipo: usuario['tipo'],
          );
        }
      }
    } catch (e) {
      print('Erro ao inicializar usuários padrão: $e');
    }
  }
}
