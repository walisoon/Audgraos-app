// Script para testar conexão com Supabase
// Execute este código no Flutter para debugar

import 'dart:convert';
import 'package:http/http.dart' as http;

void testarSupabase() async {
  const supabaseUrl = 'https://oowbeehssifgizhgxgpc.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vd2JlZWhzc2lmZ2l6aGd4Z3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQ2NzUzNDcsImV4cCI6MjA0MDI1MTM0N30.MnESYcYqAGGc8pC2x4Fw9q8hLgFhJh2nN4nWkQlYqo';

  print('=== TESTANDO CONEXÃO COM SUPABASE ===');
  
  // 1. Testar conexão básica
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/laudos?select=count(*)'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('Conexão OK!');
    } else {
      print('Erro na conexão: ${response.statusCode}');
    }
  } catch (e) {
    print('Erro de conexão: $e');
  }
  
  // 2. Testar inserção simples
  try {
    final laudoTeste = {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'numero_laudo': 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      'servico': 'Teste',
      'data': DateTime.now().toString().substring(0, 10),
      'status': 'test',
    };
    
    print('Enviando laudo teste: $laudoTeste');
    
    final response = await http.post(
      Uri.parse('$supabaseUrl/rest/v1/laudos'),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
        'Prefer': 'return=minimal',
      },
      body: jsonEncode(laudoTeste),
    ).timeout(Duration(seconds: 10));
    
    print('Status POST: ${response.statusCode}');
    print('Body POST: ${response.body}');
    
    if (response.statusCode == 201) {
      print('Inserção OK!');
      
      // Limpar laudo de teste
      await http.delete(
        Uri.parse('$supabaseUrl/rest/v1/laudos?id=eq.${laudoTeste['id']}'),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );
      print('Laudo teste removido');
    } else {
      print('Erro na inserção: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Erro na inserção: $e');
  }
}
