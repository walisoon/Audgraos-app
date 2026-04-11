import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// SCRIPT PARA DEBUGGAR E CORRIGIR STORAGE DE LAUDOS
/// Execute este script para diagnosticar problemas no storage local

class StorageDebugger {
  
  // Mostrar todos os dados do storage
  static Future<void> mostrarTodosDadosStorage() async {
    print('\n=== DEBUG COMPLETO DO STORAGE ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      print('Total de chaves no storage: ${keys.length}');
      print('Chaves encontradas:');
      
      for (String key in keys) {
        final value = prefs.get(key);
        print('  $key: ${value.runtimeType} = ${value.toString().length > 100 ? value.toString().substring(0, 100) + "..." : value}');
        
        // Se for lista de laudos, mostrar detalhes
        if (key.contains('laudos') && value is String) {
          try {
            final laudos = jsonDecode(value);
            if (laudos is List) {
              print('    -> ${laudos.length} laudos na lista');
              for (int i = 0; i < laudos.length; i++) {
                final laudo = laudos[i];
                print('      Laudo $i: ID=${laudo['id']}, Resultado="${laudo['resultado']}", Status=${laudo['status']}');
              }
            }
          } catch (e) {
            print('    -> ERRO ao decodificar: $e');
          }
        }
      }
    } catch (e) {
      print('ERRO ao acessar storage: $e');
    }
  }
  
  // Mostrar laudos de um usuário específico
  static Future<void> mostrarLaudosUsuario(String userId) async {
    print('\n=== LAUDOS DO USUÁRIO: $userId ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'laudos_cadastrados_$userId';
      final laudosJson = prefs.getString(userKey);
      
      if (laudosJson == null) {
        print('Nenhum laudo encontrado para o usuário $userId');
        return;
      }
      
      final laudos = jsonDecode(laudosJson);
      print('Total de laudos: ${laudos.length}');
      
      for (int i = 0; i < laudos.length; i++) {
        final laudo = laudos[i];
        print('\n--- LAUDO $i ---');
        print('ID: ${laudo['id']}');
        print('Número: ${laudo['numero_laudo']}');
        print('Status: ${laudo['status']}');
        print('Resultado: "${laudo['resultado']}"');
        print('Sincronizado: ${laudo['sincronizado']}');
        print('Data: ${laudo['data']}');
        print('Todos os campos: ${laudo.keys.toList()}');
      }
    } catch (e) {
      print('ERRO ao carregar laudos do usuário: $e');
    }
  }
  
  // Corrigir laudo específico no storage
  static Future<void> corrigirLaudoNoStorage(String userId, String laudoId, Map<String, dynamic> dadosCorrecao) async {
    print('\n=== CORRIGINDO LAUDO $laudoId DO USUÁRIO $userId ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = 'laudos_cadastrados_$userId';
      final laudosJson = prefs.getString(userKey);
      
      if (laudosJson == null) {
        print('Nenhum laudo encontrado para o usuário $userId');
        return;
      }
      
      final laudos = jsonDecode(laudosJson);
      bool encontrado = false;
      
      for (int i = 0; i < laudos.length; i++) {
        final laudo = laudos[i];
        if (laudo['id'].toString() == laudoId) {
          print('Laudo encontrado antes da correção:');
          print('  Resultado: "${laudo['resultado']}"');
          print('  Status: ${laudo['status']}');
          
          // Aplicar correções
          laudos[i] = {...laudo, ...dadosCorrecao};
          
          print('Laudo após correção:');
          print('  Resultado: "${laudos[i]['resultado']}"');
          print('  Status: ${laudos[i]['status']}');
          
          encontrado = true;
          break;
        }
      }
      
      if (encontrado) {
        // Salvar de volta no storage
        await prefs.setString(userKey, jsonEncode(laudos));
        print('Laudo corrigido e salvo no storage!');
      } else {
        print('Laudo $laudoId não encontrado para o usuário $userId');
      }
    } catch (e) {
      print('ERRO ao corrigir laudo no storage: $e');
    }
  }
  
  // Limpar storage corrompido
  static Future<void> limparStorageCorrompido() async {
    print('\n=== LIMPANDO STORAGE CORROMPIDO ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (String key in keys) {
        if (key.contains('laudos')) {
          print('Removendo chave: $key');
          await prefs.remove(key);
        }
      }
      
      print('Storage de laudos limpo!');
    } catch (e) {
      print('ERRO ao limpar storage: $e');
    }
  }
}

// Função principal para executar todos os debugs
Future<void> executarDebugCompleto() async {
  print('INICIANDO DEBUG COMPLETO DO STORAGE...');
  
  // 1. Mostrar todos os dados
  await StorageDebugger.mostrarTodosDadosStorage();
  
  // 2. Mostrar laudos do usuário atual
  await StorageDebugger.mostrarLaudosUsuario('audgraos_admin');
  
  // 3. Exemplo de correção (descomente se necessário)
  // await StorageDebugger.corrigirLaudoNoStorage(
  //   'audgraos_admin', 
  //   '1775928627124', 
  //   {'resultado': 'CORRIGIDO', 'status': 'Concluído'}
  // );
  
  print('\nDEBUG COMPLETO FINALIZADO!');
}

// Para executar este script, chame:
// await executarDebugCompleto();
