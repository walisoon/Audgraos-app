import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'supabase_service.dart';
import 'laudos_service.dart';

enum SyncStatus {
  idle,           // Ocioso
  syncing,        // Sincronizando
  success,        // Sucesso
  error,          // Erro
  offline         // Offline
}

class SyncService {
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingSyncKey = 'pending_sync_data';
  
  // Status da sincronização
  static bool _isSyncing = false;
  static bool get isSyncing => _isSyncing;
  
  // Stream para notificar mudanças no status
  static final StreamController<SyncStatus> _statusController = 
      StreamController<SyncStatus>.broadcast();
  static Stream<SyncStatus> get statusStream => _statusController.stream;

  // Verificar se há conexão com internet
  static Future<bool> _hasInternetConnection() async {
    try {
      // Testar com múltiplos endpoints para garantir
      final endpoints = [
        'https://httpbin.org/get', // Endpoint de teste confiável
        'https://oowbeehssifgizhgxgpc.supabase.co/rest/v1/users?select=count&limit=1',
        'https://google.com', // Backup
      ];
      
      for (String endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint)
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode == 200) {
            print('Conexão bem-sucedida com: $endpoint');
            return true;
          }
        } catch (e) {
          print('Falha com $endpoint: $e');
          continue;
        }
      }
      
      return false;
    } catch (e) {
      print('Erro geral ao testar conexão: $e');
      return false;
    }
  }

  // Sincronização manual (botão no menu)
  static Future<SyncResult> syncManual() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sincronização já em andamento...');
    }

    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        _statusController.add(SyncStatus.offline);
        return SyncResult(success: false, message: 'Sem conexão com a internet');
      }

      // Sincronizar usuários
      final usuariosResult = await _syncUsuarios();
      
      // Sincronizar laudos
      final laudosResult = await _syncLaudos();
      
      // Sincronizar outros dados (auditorias, etc.)
      // final auditoriasResult = await _syncAuditorias();

      // Salvar timestamp da última sincronização
      await _saveLastSyncTimestamp();

      _statusController.add(SyncStatus.success);
      return SyncResult(
        success: true, 
        message: 'Dados sincronizados com sucesso!',
        details: {
          'usuarios': usuariosResult,
          'laudos': laudosResult,
          // 'auditorias': auditoriasResult,
        }
      );

    } catch (e) {
      _statusController.add(SyncStatus.error);
      return SyncResult(success: false, message: 'Erro na sincronização: $e');
    } finally {
      _isSyncing = false;
      _statusController.add(SyncStatus.idle);
    }
  }

  // Sincronização automática (quando ficar online)
  static Future<void> syncAuto() async {
    if (_isSyncing) return;

    try {
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) return;

      // Verificar se há dados pendentes
      final pendingData = await _getPendingSyncData();
      if (pendingData.isEmpty) return;

      print('Iniciando sincronização automática...');
      await syncManual();

    } catch (e) {
      print('Erro na sincronização automática: $e');
    }
  }

  // Sincronizar usuários
  static Future<Map<String, dynamic>> _syncUsuarios() async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosLocaisJson = prefs.getString('usuarios_cadastrados');
    
    int enviados = 0;
    int erros = 0;

    if (usuariosLocaisJson != null) {
      try {
        final List<dynamic> usuariosLocais = jsonDecode(usuariosLocaisJson);
        
        for (var usuario in usuariosLocais) {
          try {
            // Verificar se usuário já existe no Supabase
            final existe = await SupabaseService.emailExiste(usuario['email']);
            
            if (!existe) {
              // Adicionar ao Supabase
              await SupabaseService.adicionarUsuario(
                email: usuario['email'],
                senha: usuario['senha'],
                nome: usuario['nome'],
                tipo: usuario['tipo'],
              );
              enviados++;
            }
          } catch (e) {
            erros++;
            print('Erro ao sincronizar usuário ${usuario['email']}: $e');
          }
        }

        // Limpar dados locais após sincronização bem-sucedida
        if (enviados > 0 && erros == 0) {
          await prefs.remove('usuarios_cadastrados');
        }

      } catch (e) {
        print('Erro ao processar usuários locais: $e');
      }
    }

    return {
      'enviados': enviados,
      'erros': erros,
      'total': enviados + erros,
    };
  }

  // Sincronizar laudos
  static Future<Map<String, dynamic>> _syncLaudos() async {
    try {
      // Sincronizar laudos pendentes primeiro
      final pendentesResult = await LaudosService.sincronizarPendentes();
      
      // Depois, carregar laudos do Supabase e atualizar cache local
      final laudosSupabase = await SupabaseService.carregarLaudos();
      
      if (laudosSupabase.isNotEmpty) {
        // Salvar localmente para cache
        final prefs = await SharedPreferences.getInstance();
        final laudosJson = jsonEncode(laudosSupabase);
        await prefs.setString('laudos_cadastrados', laudosJson);
      }

      return {
        'enviados': pendentesResult['sincronizados'],
        'erros': pendentesResult['erros'],
        'total': pendentesResult['total'],
        'cache_atualizado': laudosSupabase.length,
      };
    } catch (e) {
      print('Erro ao sincronizar laudos: $e');
      return {
        'enviados': 0,
        'erros': 1,
        'total': 0,
        'erro': e.toString(),
      };
    }
  }

  // Salvar timestamp da última sincronização
  static Future<void> _saveLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Obter timestamp da última sincronização
  static Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    
    if (timestamp != null) {
      return DateTime.parse(timestamp);
    }
    return null;
  }

  // Salvar dados pendentes para sincronização
  static Future<void> _savePendingSyncData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final existingData = prefs.getString(_pendingSyncKey);
    
    List<Map<String, dynamic>> pendingData = [];
    if (existingData != null) {
      pendingData = List<Map<String, dynamic>>.from(jsonDecode(existingData));
    }
    
    pendingData.add({
      ...data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(_pendingSyncKey, jsonEncode(pendingData));
  }

  // Obter dados pendentes
  static Future<List<Map<String, dynamic>>> _getPendingSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingData = prefs.getString(_pendingSyncKey);
    
    if (pendingData != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(pendingData));
    }
    return [];
  }

  // Limpar dados pendentes
  static Future<void> _clearPendingSyncData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSyncKey);
  }

  // Forçar sincronização completa (upload todos os dados)
  static Future<SyncResult> forceFullSync() async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sincronização já em andamento...');
    }

    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      final hasInternet = await _hasInternetConnection();
      if (!hasInternet) {
        _statusController.add(SyncStatus.offline);
        return SyncResult(success: false, message: 'Sem conexão com a internet');
      }

      // Forçar sincronização de todos os dados locais
      final prefs = await SharedPreferences.getInstance();
      
      // Sincronizar usuários
      await _syncUsuarios();
      
      // Aqui vamos adicionar sincronização de outros dados no futuro
      // await _forceSyncLaudos();
      // await _forceSyncAuditorias();
      // await _forceSyncClientes();
      // await _forceSyncOrdensServico();

      await _saveLastSyncTimestamp();
      await _clearPendingSyncData();

      _statusController.add(SyncStatus.success);
      return SyncResult(
        success: true, 
        message: 'Sincronização forçada concluída com sucesso!'
      );

    } catch (e) {
      _statusController.add(SyncStatus.error);
      return SyncResult(success: false, message: 'Erro na sincronização forçada: $e');
    } finally {
      _isSyncing = false;
      _statusController.add(SyncStatus.idle);
    }
  }

  // Iniciar monitoramento automático
  static void startAutoSyncMonitoring() {
    // Verificar conexão a cada 30 segundos
    Stream.periodic(const Duration(seconds: 30)).listen((_) async {
      await syncAuto();
    });
  }

  // Dispose do stream controller
  static void dispose() {
    _statusController.close();
  }
}

class SyncResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? details;

  SyncResult({
    required this.success, 
    required this.message, 
    this.details
  });
}
