import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

class LaudosService {
  static const String _laudosKey = 'laudos_cadastrados';

  // Carregar laudos com sincronização automática
  static Future<List<Map<String, dynamic>>> carregarLaudos() async {
    try {
      // Tentar carregar do Supabase primeiro
      final laudosSupabase = await SupabaseService.carregarLaudos();
      
      if (laudosSupabase.isNotEmpty) {
        // Salvar localmente para cache
        await _salvarLaudosLocal(laudosSupabase);
        return laudosSupabase;
      }
      
      // Se falhar, carregar do storage local
      return await _carregarLaudosLocal();
      
    } catch (e) {
      debugPrint('Erro ao carregar laudos do Supabase: $e');
      // Fallback para dados locais
      return await _carregarLaudosLocal();
    }
  }

  // Adicionar laudo com sincronização automática
  static Future<void> adicionarLaudo(Map<String, dynamic> laudo) async {
    try {
      print('=== INÍCIO: ADICIONAR LAUDO ===');
      print('Dados recebidos: ${laudo.keys.toList()}');
      
      // Garantir que o laudo tenha todos os campos necessários
      final laudoCompleto = Map<String, dynamic>.from(laudo);
      
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
      
      print('Laudo completo para enviar: $laudoCompleto');
      
      // Tentar adicionar no Supabase primeiro
      print('🚀 TENTANDO ENVIAR PARA SUPABASE...');
      await SupabaseService.adicionarLaudo(laudoCompleto);
      
      // Se sucesso, adicionar localmente também
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
      
      // Fallback: salvar apenas localmente
      print('💾 SALVANDO APENAS LOCALMENTE (FALLBACK)...');
      await _adicionarLaudoLocal(laudo);
      
      // Marcar como pendente para sincronização
      print('📋 MARCANDO COMO PENDENTE...');
      await _marcarComoPendente(laudo, 'adicionar');
      
      print('📱 Laudo adicionado localmente (pendente sincronização): ${laudo['numero_laudo'] ?? 'sem número'}');
      
      // Relançar erro para mostrar na UI
      throw Exception(erroMsg);
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

  // Atualizar laudo com sincronização automática
  static Future<void> atualizarLaudo(String id, Map<String, dynamic> dadosAtualizados) async {
    try {
      // Tentar atualizar no Supabase primeiro
      await SupabaseService.atualizarLaudo(id, dadosAtualizados);
      
      // Se sucesso, atualizar localmente também
      await _atualizarLaudoLocal(id, dadosAtualizados);
      
      debugPrint('Laudo atualizado com sucesso no Supabase: $id');
    } catch (e) {
      debugPrint('Falha ao atualizar do Supabase, atualizando localmente: $e');
      
      // Fallback: atualizar apenas localmente
      await _atualizarLaudoLocal(id, dadosAtualizados);
      
      // Marcar como pendente para sincronização
      await _marcarComoPendente({'id': id, ...dadosAtualizados}, 'atualizar');
      
      debugPrint('Laudo atualizado localmente (pendente sincronização): $id');
    }
  }

  // Métodos locais
  static Future<List<Map<String, dynamic>>> _carregarLaudosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final laudosJson = prefs.getString(_laudosKey);
      
      if (laudosJson != null) {
        final List<dynamic> laudosList = jsonDecode(laudosJson);
        return laudosList.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao carregar laudos locais: $e');
      return [];
    }
  }

  static Future<void> _salvarLaudosLocal(List<Map<String, dynamic>> laudos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final laudosJson = jsonEncode(laudos);
      await prefs.setString(_laudosKey, laudosJson);
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
      final laudos = await _carregarLaudosLocal();
      final index = laudos.indexWhere((laudo) => laudo['id'].toString() == id);
      
      if (index != -1) {
        // Atualizar dados
        laudos[index] = {...laudos[index], ...dadosAtualizados};
        
        // Adicionar timestamp de atualização
        laudos[index]['updated_at'] = DateTime.now().toIso8601String();
        
        await _salvarLaudosLocal(laudos);
      }
    } catch (e) {
      debugPrint('Erro ao atualizar laudo localmente: $e');
    }
  }

  // Marcar como pendente para sincronização
  static Future<void> _marcarComoPendente(Map<String, dynamic> dados, String operacao) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendentesKey = 'laudos_pendentes';
      
      List<Map<String, dynamic>> pendentes = [];
      final pendentesJson = prefs.getString(pendentesKey);
      
      if (pendentesJson != null) {
        pendentes = List<Map<String, dynamic>>.from(jsonDecode(pendentesJson));
      }
      
      pendentes.add({
        'dados': dados,
        'operacao': operacao,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(pendentesKey, jsonEncode(pendentes));
    } catch (e) {
      debugPrint('Erro ao marcar laudo como pendente: $e');
    }
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
}
