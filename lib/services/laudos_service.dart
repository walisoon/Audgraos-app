import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class LaudosService {
  static const String _laudosKey = 'laudos_cadastrados';
  
  // Obter chave específica do usuário
  static String _getUserLaudosKey() {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      return '${_laudosKey}_${currentUser.uid}';
    }
    return _laudosKey;
  }

  // Carregar laudos com sincronização automática
  static Future<List<Map<String, dynamic>>> carregarLaudos() async {
    try {
      debugPrint('=== CARREGANDO LAUDOS - APENAS DADOS LOCAIS ===');
      
      // 1. USAR APENAS DADOS LOCAIS - NUNCA CARREGAR DO SUPABASE
      final laudosLocais = await _carregarLaudosLocal();
      debugPrint('Laudos locais carregados: ${laudosLocais.length}');
      
      // 2. SEMPRE retornar dados locais (são os mais recentes)
      debugPrint('USANDO EXCLUSIVAMENTE DADOS LOCAIS');
      return laudosLocais;
      
    } catch (e) {
      debugPrint('Erro ao carregar laudos locais: $e');
      // Se falhar, tentar carregar do Supabase como último recurso
      try {
        debugPrint('Tentando carregar do Supabase como fallback');
        final laudosSupabase = await SupabaseService.carregarLaudos();
        await _salvarLaudosLocal(laudosSupabase);
        return laudosSupabase;
      } catch (supabaseError) {
        debugPrint('Falha total: $supabaseError');
        return [];
      }
    }
  }
  
  // MODO EXCLUSIVAMENTE LOCAL (para página Laudos)
  static Future<List<Map<String, dynamic>>> carregarLaudosApenasLocal() async {
    try {
      debugPrint('=== CARREGANDO LAUDOS - MODO LOCAL EXCLUSIVO ===');
      debugPrint('📱 PÁGINA LAUDOS: NUNCA CARREGA DO SUPABASE');
      
      // Carregar APENAS do storage local
      final laudosLocais = await _carregarLaudosLocal();
      debugPrint('✅ Laudos locais carregados: ${laudosLocais.length}');
      
      return laudosLocais;
      
    } catch (e) {
      debugPrint('❌ Erro ao carregar laudos locais: $e');
      return []; // Retornar lista vazia em caso de erro
    }
  }

  // Adicionar laudo com sincronização automática
  static Future<void> adicionarLaudo(Map<String, dynamic> laudo) async {
    try {
      print('=== INÍCIO: ADICIONAR LAUDO ===');
      print('Dados recebidos: ${laudo.keys.toList()}');
      
      // Garantir que o laudo tenha todos os campos necessários
      final laudoCompleto = Map<String, dynamic>.from(laudo);
      
      // VALIDAÇÃO CRÍTICA: Garantir ID sempre exista e não seja vazio
      String? idExistente = laudoCompleto['id']?.toString();
      if (idExistente == null || idExistente.isEmpty) {
        laudoCompleto['id'] = DateTime.now().millisecondsSinceEpoch.toString();
        print('✅ ID gerado para novo laudo: ${laudoCompleto['id']}');
      } else {
        print('✅ ID existente mantido: $idExistente');
      }
      
      // Adicionar campos obrigatórios se não existirem
      if (!laudoCompleto.containsKey('numero_laudo') || laudoCompleto['numero_laudo'] == null) {
        laudoCompleto['numero_laudo'] = gerarNumeroLaudo();
      }
      
      if (!laudoCompleto.containsKey('created_at')) {
        laudoCompleto['created_at'] = DateTime.now().toIso8601String();
      }
      
      if (!laudoCompleto.containsKey('status')) {
        laudoCompleto['status'] = 'rascunho';
      }
      
      // Marcar como não sincronizado inicialmente
      laudoCompleto['sincronizado'] = false;
      
      print('Laudo completo para enviar: $laudoCompleto');
      
      // Tentar adicionar no Supabase primeiro
      print('🚀 TENTANDO ENVIAR PARA SUPABASE...');
      await SupabaseService.adicionarLaudo(laudoCompleto);
      
      // Se sucesso, marcar como sincronizado e adicionar localmente
      laudoCompleto['sincronizado'] = true;
      print('💾 SALVANDO LOCALMENTE...');
      await _adicionarLaudoLocal(laudoCompleto);
      
      print('✅ SUCESSO COMPLETO: Laudo adicionado no Supabase e localmente');
    } catch (e) {
      print('❌ ERRO DETALHADO AO ENVIAR PARA SUPABASE:');
      print('Erro: $e');
      print('Tipo: ${e.runtimeType}');
      
      // Mostrar erro mais claro
      String erroMsg = e.toString();
      if (e.toString().contains('404')) {
        erroMsg = '❌ Tabela "laudos" não encontrada no Supabase. Execute o SQL fornecido.';
      } else if (e.toString().contains('403')) {
        erroMsg = '❌ Sem permissão para acessar tabela. Configure RLS policies.';
      } else if (e.toString().contains('401')) {
        erroMsg = '❌ Chave API inválida. Verifique configuração.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('Host')) {
        erroMsg = '❌ Sem conexão com internet ou servidor offline.';
      } else if (e.toString().contains('Timeout')) {
        erroMsg = '❌ Servidor demorou para responder.';
      }
      
      print('Mensagem de erro: $erroMsg');
      
      // Fallback: salvar apenas localmente (já marcado como não sincronizado)
      print('💾 SALVANDO APENAS LOCALMENTE (FALLBACK)...');
      await _adicionarLaudoLocal(laudo);
      
      // Marcar como pendente para sincronização
      print('📋 MARCANDO COMO PENDENTE...');
      await _marcarComoPendente(laudo, 'adicionar');
      
      print('📱 Laudo adicionado localmente (pendente sincronização): ${laudo['numero_laudo'] ?? 'sem número'}');
      
      // Não relançar erro - apenas mostrar warning
      print('⚠️ ATENÇÃO: Laudo salvo localmente, mas não sincronizado com nuvem');
      // throw Exception(erroMsg); // ❌ COMENTADO - Não impede adição local
    }
  }

  // Excluir laudo com sincronização automática
  static Future<void> excluirLaudo(String id, {String? numeroLaudo}) async {
    try {
      // Tentar excluir do Supabase primeiro
      await SupabaseService.excluirLaudo(id);
      
      // Se sucesso, excluir localmente também
      await _excluirLaudoLocal(id);
      
      debugPrint('Laudo excluído com sucesso do Supabase: $id');
    } catch (e) {
      debugPrint('Falha ao excluir do Supabase, excluindo localmente: $e');
      
      // Fallback: excluir apenas localmente
      await _excluirLaudoLocal(id);
      
      // Marcar como pendente para sincronização
      await _marcarComoPendente({'id': id, 'numero_laudo': numeroLaudo}, 'excluir');
      
      debugPrint('Laudo excluído localmente (pendente sincronização): $id');
    }
  }

  // Atualizar laudo - MODO LOCAL + ENVIO AUTOMÁTICO PARA SUPABASE
  static Future<Map<String, dynamic>> atualizarLaudo(String id, Map<String, dynamic> dadosAtualizados) async {
    try {
      debugPrint('=== ATUALIZANDO LAUDO - MODO LOCAL + ENVIO SUPABASE ===');
      
      // 1. ATUALIZAR LOCALMENTE PRIMEIRO (sempre funciona)
      await _atualizarLaudoLocal(id, dadosAtualizados);
      debugPrint('✅ Laudo atualizado localmente: $id');
      
      // 2. ENVIAR PARA SUPABASE DE FORMA SÍNCRONA COM FEEDBACK
      debugPrint('📤 ENVIANDO PARA O SUPABASE (AGUARDANDO RESPOSTA)...');
      
      try {
        await SupabaseService.atualizarLaudo(id, dadosAtualizados);
        debugPrint('✅ Dados enviados com sucesso para o Supabase: $id');
        
        // Marcar como sincronizado se sucesso
        await _marcarComoSincronizadoLocal(id);
        debugPrint('✅ Laudo marcado como sincronizado: $id');
        
      } catch (error) {
        debugPrint('❌ ERRO AO ENVIAR PARA SUPABASE: $error');
        debugPrint('⚠️ Laudo foi salvo localmente, mas falhou ao sincronizar com Supabase');
        
        // Marcar como pendente para tentar depois
        final laudos = await _carregarLaudosLocal();
        final laudo = laudos.firstWhere((l) => l['id'].toString() == id, orElse: () => {});
        if (laudo.isNotEmpty) {
          await _marcarComoPendente(laudo, 'atualizar');
          debugPrint('📋 Laudo marcado como pendente: $id');
        }
      }
      
      // 3. RETORNAR DADOS LOCAIS IMEDIATAMENTE (sem esperar Supabase)
      final laudos = await _carregarLaudosLocal();
      final laudoAtualizado = laudos.firstWhere(
        (l) => l['id'].toString() == id,
        orElse: () => dadosAtualizados,
      );
      
      debugPrint('✅ Laudo atualizado localmente e envio iniciado para Supabase');
      debugPrint('Retornando laudo atualizado: ${laudoAtualizado['numero_laudo']}');
      return laudoAtualizado;
      
    } catch (e) {
      debugPrint('❌ Erro crítico ao atualizar laudo: $e');
      throw e;
    }
  }

  // Métodos locais
  static Future<List<Map<String, dynamic>>> _carregarLaudosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserLaudosKey();
      final laudosJson = prefs.getString(userKey) ?? '[]';
      final laudos = jsonDecode(laudosJson).cast<Map<String, dynamic>>();
      debugPrint('=== ${laudos.length} LAUDOS CARREGADOS LOCALMENTE (CHAVE: $userKey) ===');
      return laudos;
    } catch (e) {
      debugPrint('Erro ao carregar laudos locais: $e');
      return [];
    }
  }

  static Future<void> _salvarLaudosLocal(List<Map<String, dynamic>> laudos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserLaudosKey();
      final laudosJson = jsonEncode(laudos);
      await prefs.setString(userKey, laudosJson);
      debugPrint('=== ${laudos.length} LAUDOS SALVOS LOCALMENTE (CHAVE: $userKey) ===');
    } catch (e) {
      debugPrint('Erro ao salvar laudos localmente: $e');
    }
  }

  static Future<void> _adicionarLaudoLocal(Map<String, dynamic> laudo) async {
    try {
      final laudos = await _carregarLaudosLocal();
      
      // Garantir que o laudo tenha todos os campos necessários
      final laudoCompleto = Map<String, dynamic>.from(laudo);
      
      // Gerar ID se não existir
      if (laudoCompleto['id'] == null) {
        laudoCompleto['id'] = DateTime.now().millisecondsSinceEpoch.toString();
      }
      
      // Adicionar timestamp se não existir
      if (laudoCompleto['created_at'] == null) {
        laudoCompleto['created_at'] = DateTime.now().toIso8601String();
      }
      
      // Adicionar user_id do usuário atual
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        laudoCompleto['user_id'] = currentUser.uid;
        debugPrint('=== ADICIONANDO user_id: ${currentUser.uid} ===');
      }
      
      // Garantir campos para o PDF
      laudoCompleto['numero_laudo'] = laudoCompleto['numero_laudo'] ?? 'LAU-${DateTime.now().millisecondsSinceEpoch}';
      laudoCompleto['status'] = laudoCompleto['status'] ?? 'rascunho';
      laudoCompleto['titulo'] = laudoCompleto['titulo'] ?? 'Laudo';
      laudoCompleto['data'] = laudoCompleto['data'] ?? DateTime.now().toString().substring(0, 10);
      laudoCompleto['servico'] = laudoCompleto['servico'] ?? 'Análise';
      laudoCompleto['placa'] = laudoCompleto['placa'] ?? '';
      laudoCompleto['peso'] = laudoCompleto['peso'] ?? '';
      laudoCompleto['umidade'] = laudoCompleto['umidade'] ?? '';
      laudoCompleto['materiasEstranhas'] = laudoCompleto['materiasEstranhas'] ?? '';
      laudoCompleto['queimados'] = laudoCompleto['queimados'] ?? '';
      laudoCompleto['ardidos'] = laudoCompleto['ardidos'] ?? '';
      laudoCompleto['mofados'] = laudoCompleto['mofados'] ?? '';
      
      laudos.add(laudoCompleto);
      await _salvarLaudosLocal(laudos);
      
      print('Laudo salvo localmente com todos os campos: ${laudoCompleto.keys.toList()}');
    } catch (e) {
      print('Erro ao adicionar laudo localmente: $e');
    }
  }

  static Future<void> _excluirLaudoLocal(String id) async {
    try {
      final laudos = await _carregarLaudosLocal();
      laudos.removeWhere((laudo) => laudo['id'].toString() == id);
      await _salvarLaudosLocal(laudos);
    } catch (e) {
      debugPrint('Erro ao excluir laudo localmente: $e');
    }
  }

  static Future<void> _atualizarLaudoLocal(String id, Map<String, dynamic> dadosAtualizados) async {
    try {
      debugPrint('=== INICIANDO ATUALIZAÇÃO LOCAL ===');
      debugPrint('ID do laudo a atualizar: $id');
      debugPrint('Dados a atualizar: $dadosAtualizados');
      
      final laudos = await _carregarLaudosLocal();
      debugPrint('Total de laudos locais: ${laudos.length}');
      
      final index = laudos.indexWhere((laudo) {
        final laudoId = laudo['id']?.toString() ?? '';
        final buscaId = id.toString();
        debugPrint('Comparando: "$laudoId" == "$buscaId" -> ${laudoId == buscaId}');
        return laudoId == buscaId;
      });
      
      debugPrint('Índice encontrado: $index');
      
      if (index != -1) {
        debugPrint('Laudo encontrado antes da atualização: ${laudos[index]}');
        
        // Manter user_id existente
        final userIdExistente = laudos[index]['user_id'];
        
        // Atualizar dados
        laudos[index] = {...laudos[index], ...dadosAtualizados};
        
        debugPrint('Laudo após atualização: ${laudos[index]}');
        debugPrint('Resultado após atualização: "${laudos[index]['resultado']}"');
        
        // Garantir que user_id não seja perdido
        if (userIdExistente != null) {
          laudos[index]['user_id'] = userIdExistente;
        }
        
        // Adicionar timestamp de atualização
        laudos[index]['updated_at'] = DateTime.now().toIso8601String();
        
        await _salvarLaudosLocal(laudos);
        debugPrint('=== ATUALIZAÇÃO LOCAL CONCLUÍDA ===');
      } else {
        debugPrint('❌ LAUDO NÃO ENCONTRADO LOCALMENTE PARA ATUALIZAÇÃO');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar laudo localmente: $e');
    }
  }

  // Marcar como pendente para sincronização
  // Marcar laudo como sincronizado localmente
  static Future<void> _marcarComoSincronizadoLocal(String id) async {
    try {
      final laudos = await _carregarLaudosLocal();
      final index = laudos.indexWhere((l) => l['id'].toString() == id);
      
      if (index != -1) {
        laudos[index]['sincronizado'] = true;
        laudos[index]['updated_at'] = DateTime.now().toIso8601String();
        
        final prefs = await SharedPreferences.getInstance();
        final userKey = _getUserLaudosKey();
        await prefs.setString(userKey, jsonEncode(laudos));
        
        debugPrint('✅ Laudo $id marcado como sincronizado localmente');
      }
    } catch (e) {
      debugPrint('Erro ao marcar laudo como sincronizado: $e');
    }
  }

  static Future<void> _marcarComoPendente(Map<String, dynamic> dados, String operacao) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendentes = prefs.getStringList('laudos_pendentes') ?? [];
      
      pendentes.add(jsonEncode({
        'dados': dados,
        'operacao': operacao,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      await prefs.setStringList('laudos_pendentes', pendentes);
      debugPrint('Laudo marcado como pendente: ${dados['id']}');
    } catch (e) {
      debugPrint('Erro ao marcar laudo como pendente: $e');
    }
  }

  // Limpar cache local para forçar recarregamento do Supabase
  static Future<void> _limparCacheLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserLaudosKey();
      await prefs.remove(userKey);
      debugPrint('Cache local limpo: $userKey');
    } catch (e) {
      debugPrint('Erro ao limpar cache local: $e');
    }
  }
  
  // DEBUG COMPLETO DO STORAGE
  static Future<void> debugCompletoStorage() async {
    debugPrint('\n=== DEBUG COMPLETO DO STORAGE ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      debugPrint('Total de chaves no storage: ${keys.length}');
      debugPrint('Chaves encontradas:');
      
      for (String key in keys) {
        final value = prefs.get(key);
        debugPrint('  $key: ${value.runtimeType} = ${value.toString().length > 100 ? value.toString().substring(0, 100) + "..." : value}');
        
        // Se for lista de laudos, mostrar detalhes
        if (key.contains('laudos') && value is String) {
          try {
            final laudos = jsonDecode(value);
            if (laudos is List) {
              debugPrint('    -> ${laudos.length} laudos na lista');
              for (int i = 0; i < laudos.length; i++) {
                final laudo = laudos[i];
                debugPrint('      Laudo $i: ID=${laudo['id']}, Resultado="${laudo['resultado']}", Status=${laudo['status']}');
              }
            }
          } catch (e) {
            debugPrint('    -> ERRO ao decodificar: $e');
          }
        }
      }
      
      // Mostrar laudos do usuário atual
      final userKey = _getUserLaudosKey();
      final laudosJson = prefs.getString(userKey);
      
      if (laudosJson != null) {
        final laudos = jsonDecode(laudosJson);
        debugPrint('\n=== LAUDOS DO USUÁRIO ATUAL ===');
        debugPrint('Total de laudos: ${laudos.length}');
        
        for (int i = 0; i < laudos.length; i++) {
          final laudo = laudos[i];
          debugPrint('\n--- LAUDO $i ---');
          debugPrint('ID: ${laudo['id']}');
          debugPrint('Número: ${laudo['numero_laudo']}');
          debugPrint('Status: ${laudo['status']}');
          debugPrint('Resultado: "${laudo['resultado']}"');
          debugPrint('Sincronizado: ${laudo['sincronizado']}');
          debugPrint('Data: ${laudo['data']}');
          debugPrint('Todos os campos: ${laudo.keys.toList()}');
        }
      }
      
    } catch (e) {
      debugPrint('ERRO ao acessar storage: $e');
    }
    
    debugPrint('\n=== DEBUG COMPLETO FINALIZADO ===');
  }

  // Sincronizar laudos pendentes
  static Future<Map<String, dynamic>> sincronizarPendentes() async {
    int sincronizados = 0;
    int erros = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final pendentesKey = 'laudos_pendentes';
      final pendentesJson = prefs.getString(pendentesKey);
      
      if (pendentesJson != null) {
        final List<Map<String, dynamic>> pendentes = 
            List<Map<String, dynamic>>.from(jsonDecode(pendentesJson));
        
        for (var pendente in pendentes) {
          try {
            final dados = pendente['dados'];
            final operacao = pendente['operacao'];
            
            switch (operacao) {
              case 'adicionar':
                await SupabaseService.adicionarLaudo(dados);
                break;
              case 'excluir':
                await SupabaseService.excluirLaudo(dados['id']);
                break;
              case 'atualizar':
                await SupabaseService.atualizarLaudo(dados['id'], dados);
                break;
            }
            
            sincronizados++;
          } catch (e) {
            erros++;
            debugPrint('Erro ao sincronizar laudo pendente: $e');
          }
        }
        
        // Limpar pendentes após sincronização
        if (sincronizados > 0) {
          await prefs.remove(pendentesKey);
        }
      }
    } catch (e) {
      debugPrint('Erro na sincronização de laudos pendentes: $e');
    }

    return {
      'sincronizados': sincronizados,
      'erros': erros,
      'total': sincronizados + erros,
    };
  }

  // Gerar número de laudo automático
  static String gerarNumeroLaudo() {
    final agora = DateTime.now();
    final ano = agora.year.toString();
    final mes = agora.month.toString().padLeft(2, '0');
    final dia = agora.day.toString().padLeft(2, '0');
    final timestamp = agora.millisecondsSinceEpoch.toString().substring(8);
    
    return 'LAU-$ano$mes$dia-$timestamp';
  }

  // Obter laudos por status
  static Future<List<Map<String, dynamic>>> getLaudosPorStatus(String status) async {
    final todosLaudos = await carregarLaudos();
    return todosLaudos.where((laudo) => laudo['status'] == status).toList();
  }

  // Obter laudos por cliente
  static Future<List<Map<String, dynamic>>> getLaudosPorCliente(String clienteId) async {
    final todosLaudos = await carregarLaudos();
    return todosLaudos.where((laudo) => laudo['cliente_id'] == clienteId).toList();
  }

  // Limpar laudos com ID vazio do storage local
  static Future<void> limparLaudosComIdVazio() async {
    try {
      debugPrint('=== LIMPANDO LAUDOS COM ID VAZIO ===');
      
      final laudosLocais = await _carregarLaudosLocal();
      final laudosValidos = laudosLocais.where((laudo) {
        final id = laudo['id']?.toString() ?? '';
        if (id.isEmpty) {
          debugPrint('❌ Laudo removido (ID vazio): ${laudo['numero_laudo']}');
          return false;
        }
        return true;
      }).toList();
      
      if (laudosValidos.length != laudosLocais.length) {
        await _salvarLaudosLocal(laudosValidos);
        debugPrint('✅ ${laudosLocais.length - laudosValidos.length} laudos com ID vazio removidos');
      } else {
        debugPrint('✅ Nenhum laudo com ID vazio encontrado');
      }
      
    } catch (e) {
      debugPrint('Erro ao limpar laudos com ID vazio: $e');
    }
  }
  
  // Sincronizar dados locais com Supabase (enviar alterações)
  static Future<void> sincronizarDadosLocaisComSupabase() async {
    try {
      debugPrint('=== SINCRONIZANDO DADOS LOCAIS COM SUPABASE ===');
      
      // 0. Limpar laudos com ID vazio primeiro
      await limparLaudosComIdVazio();
      
      // 1. Carregar dados locais (mais recentes)
      final laudosLocais = await _carregarLaudosLocal();
      debugPrint('Laudos locais para sincronizar: ${laudosLocais.length}');
      
      // 2. Para cada laudo local, tentar sincronizar com Supabase
      for (final laudoLocal in laudosLocais) {
        try {
          final laudoId = laudoLocal['id']?.toString() ?? '';
          
          // VALIDAÇÃO: Pular laudos com ID vazio
          if (laudoId.isEmpty) {
            debugPrint('⚠️ Laudo com ID vazio ignorado: ${laudoLocal['numero_laudo']}');
            debugPrint('   Dados do laudo: $laudoLocal');
            continue;
          }
          
          debugPrint('Sincronizando laudo: ${laudoLocal['numero_laudo']} (ID: $laudoId)');
          
          // 🚨 CORREÇÃO: Verificar se existe no Supabase usando ID (não numero_laudo)
          final existeNoSupabase = await SupabaseService.laudoExistePorId(laudoId);
          debugPrint('🔍 Laudo existe no Supabase (por ID $laudoId): $existeNoSupabase');
          
          if (existeNoSupabase) {
            // Atualizar existente
            await SupabaseService.atualizarLaudo(laudoId, laudoLocal);
            debugPrint('✅ Laudo atualizado no Supabase: ${laudoLocal['numero_laudo']}');
          } else {
            // Inserir novo
            await SupabaseService.adicionarLaudo(laudoLocal);
            debugPrint('✅ Laudo adicionado ao Supabase: ${laudoLocal['numero_laudo']}');
          }
        } catch (e) {
          debugPrint('❌ Erro ao sincronizar laudo ${laudoLocal['numero_laudo']}: $e');
        }
      }
      
      debugPrint('✅ Sincronização de dados locais concluída');
      
    } catch (e) {
      debugPrint('Erro na sincronização de dados locais: $e');
    }
  }
  
  // Sincronizar manualmente com Supabase (método antigo mantido)
  static Future<void> sincronizarComSupabase() async {
    try {
      debugPrint('=== SINCRONIZANDO COM SUPABASE ===');
      
      // 1. Primeiro sincronizar dados locais com Supabase
      await sincronizarDadosLocaisComSupabase();
      
      // 2. Depois carregar dados do Supabase para mesclar
      final laudosSupabase = await SupabaseService.carregarLaudos();
      debugPrint('Laudos do Supabase: ${laudosSupabase.length}');
      
      // 3. Carregar dados locais
      final laudosLocais = await _carregarLaudosLocal();
      debugPrint('Laudos locais: ${laudosLocais.length}');
      
      // 4. Mesclar dados (prioridade para dados locais mais recentes)
      final laudosMesclados = <Map<String, dynamic>>[];
      
      // Adicionar todos os laudos locais
      for (final laudoLocal in laudosLocais) {
        final idLocal = laudoLocal['id'].toString();
        final laudoSupabase = laudosSupabase.firstWhere(
          (l) => l['id'].toString() == idLocal,
          orElse: () => laudoLocal,
        );
        
        // SEMPRE usar dados locais (são os mais recentes)
        laudosMesclados.add(laudoLocal);
        debugPrint('Mantendo dados locais: ${laudoLocal['numero_laudo']}');
      }
      
      // 5. Adicionar laudos que existem apenas no Supabase
      for (final laudoSupabase in laudosSupabase) {
        final idSupabase = laudoSupabase['id'].toString();
        if (!laudosLocais.any((l) => l['id'].toString() == idSupabase)) {
          laudosMesclados.add(laudoSupabase);
          debugPrint('Adicionando laudo do Supabase: ${laudoSupabase['numero_laudo']}');
        }
      }
      
      // 6. Salvar dados mesclados localmente
      await _salvarLaudosLocal(laudosMesclados);
      debugPrint('Sincronização concluída: ${laudosMesclados.length} laudos');
      
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
    }
  }

  // Forçar sincronização de um laudo específico
  static Future<void> sincronizarLaudoEspecifico(String laudoId) async {
    try {
      debugPrint('=== SINCRONIZANDO LAUDO ESPECÍFICO: $laudoId ===');
      
      // 1. Carregar laudos locais
      final laudosLocais = await _carregarLaudosLocal();
      
      // 2. Encontrar o laudo específico
      final index = laudosLocais.indexWhere((l) => l['id'].toString() == laudoId);
      
      if (index != -1) {
        final laudoLocal = laudosLocais[index];
        
        // 3. Enviar para Supabase
        await SupabaseService.atualizarLaudo(laudoId, laudoLocal);
        
        // 4. Marcar como sincronizado
        laudoLocal['sincronizado'] = true;
        laudosLocais[index] = laudoLocal;
        
        // 5. Salvar localmente
        await _salvarLaudosLocal(laudosLocais);
        
        debugPrint('Laudo $laudoId sincronizado com sucesso');
      } else {
        debugPrint('Laudo $laudoId não encontrado localmente');
      }
      
    } catch (e) {
      debugPrint('Erro ao sincronizar laudo $laudoId: $e');
    }
  }
}
