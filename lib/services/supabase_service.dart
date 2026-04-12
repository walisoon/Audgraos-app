import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supabase_migration_service.dart';
import 'auth_service.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://oowbeehssifgizhgxgpc.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vd2JlZWhzc2lmZ2l6aGd4Z3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzE0MjYsImV4cCI6MjA5MDkwNzQyNn0.Fqw-Yma5zP0GG1M2BGXDA1benbR84AUnWoiU_FLmyMA';

  // Obter ID do usuário atual (usando AuthService)
  static Future<String?> _getCurrentUserId() async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        debugPrint('=== USUÁRIO AUTENTICADO: ${currentUser.uid} ===');
        return currentUser.uid;
      } else {
        debugPrint('=== USUÁRIO NÃO AUTENTICADO ===');
        return null;
      }
    } catch (e) {
      debugPrint('Erro ao obter ID do usuário: $e');
      return null;
    }
  }

  // Tabelas
  static const String _usersTable = 'users';
  static const String _laudosTable = 'laudos';
  static const String _auditoriasTable = 'auditorias';
  static const String _relatoriosTable = 'relatorios';

  static Future<void> initialize() async {
    try {
      print('Supabase Service inicializado (HTTP direto)');
      
      // Simplificado: não executar migração automática para evitar erros
      // A coluna user_id será tratada no nível de aplicação
      print('=== SUPABASE SERVICE INICIALIZADO (MIGRAÇÃO DESABILITADA) ===');
    } catch (e) {
      print('Erro na inicialização: $e');
    }
  }

  // Headers padrão para requisições
  static Map<String, String> get _headers => {
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

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
        'email': 'jailson@audgraos.com',
        'senha': 'jailson1894',
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

  // Buscar todos os laudos
  static Future<List<Map<String, dynamic>>> buscarLaudos() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar laudos do Supabase: $e');
      return [];
    }
  }

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
      
      // Mapeamento simplificado para depuração
      final Map<String, dynamic> dadosMapeados = {
        'id': laudo['id']?.toString().isNotEmpty == true ? laudo['id'] : DateTime.now().millisecondsSinceEpoch,
        'numero_laudo': laudo['numero_laudo'] ?? 'LAU-${DateTime.now().millisecondsSinceEpoch}',
        'servico': laudo['servico'] ?? 'Serviço Padrão',
        'data': laudo['data'] ?? DateTime.now().toString().substring(0, 10),
        'status': laudo['status'] ?? 'rascunho',
      };
      
      // Tentar adicionar ID do usuário atual (se a coluna existir)
      final userId = await _getCurrentUserId();
      if (userId != null) {
        dadosMapeados['user_id'] = userId;
        debugPrint('=== TENTANDO ADICIONAR user_id: $userId ===');
      }
      
      // Adicionar campos opcionais apenas se existirem
      if (laudo['origem']?.toString().isNotEmpty == true) dadosMapeados['origem'] = laudo['origem'];
      if (laudo['destino']?.toString().isNotEmpty == true) dadosMapeados['destino'] = laudo['destino'];
      if (laudo['notaFiscal']?.toString().isNotEmpty == true) dadosMapeados['nota_fiscal'] = laudo['notaFiscal'];
      if (laudo['produto']?.toString().isNotEmpty == true) dadosMapeados['produto'] = laudo['produto'];
      if (laudo['cliente']?.toString().isNotEmpty == true) dadosMapeados['cliente'] = laudo['cliente'];
      if (laudo['placa']?.toString().isNotEmpty == true) dadosMapeados['placa'] = laudo['placa'];
      if (laudo['certificadora']?.toString().isNotEmpty == true) dadosMapeados['certificadora'] = laudo['certificadora'];
      if (laudo['peso']?.toString().isNotEmpty == true) dadosMapeados['peso'] = laudo['peso'];
      if (laudo['transportadora']?.toString().isNotEmpty == true) dadosMapeados['transportadora'] = laudo['transportadora'];
      if (laudo['nomeClassificador']?.toString().isNotEmpty == true) dadosMapeados['nome_classificador'] = laudo['nomeClassificador'];
      if (laudo['tipo']?.toString().isNotEmpty == true) dadosMapeados['tipo'] = laudo['tipo'];
      if (laudo['terminalRecusa']?.toString().isNotEmpty == true) dadosMapeados['terminal_recusa'] = laudo['terminalRecusa'];
      if (laudo['resultado']?.toString().isNotEmpty == true) dadosMapeados['resultado'] = laudo['resultado'];
      if (laudo['odor']?.toString().isNotEmpty == true) dadosMapeados['odor'] = laudo['odor'];
      if (laudo['sementes']?.toString().isNotEmpty == true) dadosMapeados['sementes'] = laudo['sementes'];
      if (laudo['observacoes']?.toString().isNotEmpty == true) dadosMapeados['observacoes'] = laudo['observacoes'];
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
        if (response.body.contains('user_id')) {
          print('⚠️ ERRO 400: user_id não existe na tabela, tentando sem user_id...');
          
          // Tentar novamente sem user_id
          final dadosSemUserId = Map<String, dynamic>.from(dadosMapeados);
          dadosSemUserId.remove('user_id');
          
          final responseRetry = await http.post(
            Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable'),
            headers: headersComRefresh,
            body: jsonEncode(dadosSemUserId),
          );
          
          if (responseRetry.statusCode == 201) {
            print('🎉 SUCESSO: Laudo adicionado sem user_id');
          } else {
            throw Exception('Erro ao adicionar laudo mesmo sem user_id: ${responseRetry.body}');
          }
        } else if (response.body.contains('nome_classificador')) {
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

  // Carregar todos os laudos (visão global - para página cópia)
  static Future<List<Map<String, dynamic>>> carregarTodosLaudos() async {
    try {
      debugPrint('=== CARREGANDO TODOS OS LAUDOS DO SUPABASE ===');
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?order=created_at.desc'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('=== ${data.length} LAUDOS ENCONTRADOS NO SUPABASE ===');
        return _mapearLaudos(data);
      } else {
        throw Exception('Erro ao carregar todos os laudos: ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro ao carregar todos os laudos do Supabase: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> buscarLaudoPorNumero(String numeroLaudo) async {
    try {
      final queryNumero = numeroLaudo.trim();
      if (queryNumero.isEmpty) {
        return null;
      }

      debugPrint('=== BUSCANDO LAUDO POR NUMERO NO SUPABASE: $queryNumero ===');
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?numero_laudo=eq.$queryNumero&limit=1'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return _mapearLaudo(Map<String, dynamic>.from(data.first));
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar laudo por número: $e');
    }

    return null;
  }

  // Carregar laudos do usuário atual (visão pessoal - para página original)
  static Future<List<Map<String, dynamic>>> carregarLaudos() async {
    try {
      debugPrint('=== CARREGANDO LAUDOS DO USUÁRIO DO SUPABASE ===');
      
      // Tentar filtrar por usuário (se user_id existir)
      final userId = await _getCurrentUserId();
      if (userId == null) {
        debugPrint('=== USUÁRIO NÃO AUTENTICADO ===');
        return [];
      }
      
      // Tentar carregar com filtro por user_id
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?user_id=eq.$userId&order=created_at.desc'),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('=== ${data.length} LAUDOS DO USUÁRIO ENCONTRADOS ===');
        return _mapearLaudos(data);
      } else if (response.statusCode == 400) {
        // Se der erro 400, provavelmente user_id não existe, carregar todos
        debugPrint('=== ERRO 400 - user_id não existe, carregando todos ===');
        return await carregarTodosLaudos();
      } else {
        debugPrint('=== ERRO INESPERADO: ${response.statusCode} ===');
        return [];
      }
    } catch (e) {
      debugPrint('Erro ao carregar laudos do usuário: $e');
      // Fallback para carregar todos
      return await carregarTodosLaudos();
    }
  }

  static Map<String, dynamic> _mapearLaudo(Map<String, dynamic> laudo) {
    final Map<String, dynamic> laudoMapeado = Map<String, dynamic>.from(laudo);
    
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
    
    laudoMapeado['sincronizado'] = true;
    
    return laudoMapeado;
  }

  // Método auxiliar para mapear laudos
  static List<Map<String, dynamic>> _mapearLaudos(List<dynamic> data) {
    return data.map((laudo) => _mapearLaudo(Map<String, dynamic>.from(laudo))).toList();
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

  // Atualizar laudo com upsert (POST + on_conflict=id)
  static Future<void> atualizarLaudo(String id, Map<String, dynamic> dadosAtualizados) async {
    try {
      print('=== SUPABASE: INICIANDO UPSERT ===');
      print('ID: "$id"');
      print('Dados recebidos: $dadosAtualizados');
      
      final int? parsedId = int.tryParse(id);
      final Map<String, dynamic> dadosMapeados = {
        'id': parsedId ?? id,
        if (dadosAtualizados['numero_laudo'] != null) 'numero_laudo': dadosAtualizados['numero_laudo'],
        if (dadosAtualizados['servico'] != null) 'servico': dadosAtualizados['servico'],
        if (dadosAtualizados['data'] != null) 'data': dadosAtualizados['data'],
        if (dadosAtualizados['status'] != null) 'status': dadosAtualizados['status'],
        if (dadosAtualizados['origem'] != null) 'origem': dadosAtualizados['origem'],
        if (dadosAtualizados['destino'] != null) 'destino': dadosAtualizados['destino'],
        if (dadosAtualizados['notaFiscal'] != null) 'nota_fiscal': dadosAtualizados['notaFiscal'],
        if (dadosAtualizados['produto'] != null) 'produto': dadosAtualizados['produto'],
        if (dadosAtualizados['cliente'] != null) 'cliente': dadosAtualizados['cliente'],
        if (dadosAtualizados['placa'] != null) 'placa': dadosAtualizados['placa'],
        if (dadosAtualizados['certificadora'] != null) 'certificadora': dadosAtualizados['certificadora'],
        if (dadosAtualizados['peso'] != null) 'peso': dadosAtualizados['peso'],
        if (dadosAtualizados['transportadora'] != null) 'transportadora': dadosAtualizados['transportadora'],
        if (dadosAtualizados['nomeClassificador'] != null) 'nome_classificador': dadosAtualizados['nomeClassificador'],
        if (dadosAtualizados['tipo'] != null) 'tipo': dadosAtualizados['tipo'],
        if (dadosAtualizados['terminalRecusa'] != null) 'terminal_recusa': dadosAtualizados['terminalRecusa'],
        if (dadosAtualizados.containsKey('resultado')) 'resultado': dadosAtualizados['resultado'],
        if (dadosAtualizados['odor'] != null) 'odor': dadosAtualizados['odor'],
        if (dadosAtualizados['sementes'] != null) 'sementes': dadosAtualizados['sementes'],
        if (dadosAtualizados['observacoes'] != null) 'observacoes': dadosAtualizados['observacoes'],
      };

      print('Dados para upsert: $dadosMapeados');
      final uri = Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?on_conflict=id');

      final response = await http.post(
        uri,
        headers: {
          ..._headers,
          'Prefer': 'resolution=merge-duplicates, return=minimal',
        },
        body: jsonEncode(dadosMapeados),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('Erro ao atualizar laudo (upsert): ${response.body}');
      }

      print('✅ Laudo upsertado com sucesso no Supabase');
    } catch (e) {
      throw Exception('Erro ao atualizar laudo no Supabase: $e');
    }
  }

  static Future<bool> laudoExiste(String numeroLaudo) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?numero_laudo=eq.$numeroLaudo&select=id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Erro ao verificar se laudo existe: $e');
      return false;
    }
  }
  
  // Verificar se laudo já existe por ID
  static Future<bool> laudoExistePorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_laudosTable?id=eq.$id&select=id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final existe = data.isNotEmpty;
        print('Verificação por ID $id: existe=$existe');
        return existe;
      }
      return false;
    } catch (e) {
      print('Erro ao verificar se laudo existe por ID: $e');
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

  // ====== AUDITORIAS ======

  // Buscar todas as auditorias
  static Future<List<Map<String, dynamic>>> buscarAuditorias() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_auditoriasTable?select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar auditorias: $e');
      return [];
    }
  }

  // Adicionar auditoria
  static Future<void> adicionarAuditoria(Map<String, dynamic> auditoria) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/$_auditoriasTable'),
        headers: _headers,
        body: jsonEncode({
          ...auditoria,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Erro ao adicionar auditoria: ${response.body}');
      }
    } catch (e) {
      print('Erro ao adicionar auditoria: $e');
      throw e;
    }
  }

  // ====== RELATÓRIOS ======

  // Buscar todos os relatórios
  static Future<List<Map<String, dynamic>>> buscarRelatorios() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/$_relatoriosTable?select=*'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar relatórios: $e');
      return [];
    }
  }

  // Adicionar relatório
  static Future<void> adicionarRelatorio(Map<String, dynamic> relatorio) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/$_relatoriosTable'),
        headers: _headers,
        body: jsonEncode({
          ...relatorio,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Erro ao adicionar relatório: ${response.body}');
      }
    } catch (e) {
      print('Erro ao adicionar relatório: $e');
      throw e;
    }
  }
}
