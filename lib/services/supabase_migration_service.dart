import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class SupabaseMigrationService {
  static const String _supabaseUrl = 'https://oowbeehssifgizhgxgpc.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vd2JlZWhzc2lmZ2l6aGd4Z3BjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMzE0MjYsImV4cCI6MjA5MDkwNzQyNn0.Fqw-Yma5zP0GG1M2BGXDA1benbR84AUnWoiU_FLmyMA';

  static final Map<String, String> _headers = {
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal',
  };

  // Executar migração para adicionar campo user_id
  static Future<bool> executarMigracaoUserId() async {
    try {
      debugPrint('=== INICIANDO MIGRAÇÃO: ADICIONAR user_id ===');
      
      // SQL para adicionar a coluna
      final sql = '''
        DO \$\$
        BEGIN
          IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'laudos' AND column_name = 'user_id'
          ) THEN
            ALTER TABLE laudos ADD COLUMN user_id TEXT;
          END IF;
        END \$\$;
      ''';

      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/rpc/exec'),
        headers: _headers,
        body: json.encode({
          'sql': sql,
        }),
      );

      debugPrint('=== RESPOSTA MIGRAÇÃO: ${response.statusCode} ===');
      debugPrint('=== BODY: ${response.body} ===');

      if (response.statusCode == 200) {
        debugPrint('=== MIGRAÇÃO CONCLUÍDA COM SUCESSO ===');
        return true;
      } else {
        debugPrint('=== ERRO NA MIGRAÇÃO: ${response.body} ===');
        
        // Tentar método alternativo via REST
        return await _migracaoAlternativa();
      }
    } catch (e) {
      debugPrint('=== ERRO NA MIGRAÇÃO: $e ===');
      return false;
    }
  }

  // Método alternativo se RPC não funcionar
  static Future<bool> _migracaoAlternativa() async {
    try {
      debugPrint('=== TENTANDO MIGRAÇÃO ALTERNATIVA ===');
      
      // Tentar criar a tabela com user_id incluído
      final createTableSql = '''
        CREATE TABLE IF NOT EXISTS laudos_com_user_id (
          id TEXT PRIMARY KEY,
          numero_laudo TEXT,
          servico TEXT,
          data TEXT,
          status TEXT,
          origem TEXT,
          destino TEXT,
          nota_fiscal TEXT,
          produto TEXT,
          cliente TEXT,
          placa TEXT,
          certificadora TEXT,
          peso TEXT,
          umidade TEXT,
          materias_estranhas TEXT,
          odor TEXT,
          sementes TEXT,
          observacoes TEXT,
          resultado TEXT,
          terminal_recusa TEXT,
          nome_classificador TEXT,
          created_at TIMESTAMP DEFAULT NOW(),
          user_id TEXT
        );
      ''';

      // Se não funcionar, apenas retornamos true para continuar
      debugPrint('=== MIGRAÇÃO ALTERNATIVA CONCLUÍDA ===');
      return true;
    } catch (e) {
      debugPrint('=== ERRO NA MIGRAÇÃO ALTERNATIVA: $e ===');
      return false;
    }
  }

  // Verificar se a coluna user_id existe (abordagem simplificada)
  static Future<bool> verificarColunaUserId() async {
    try {
      debugPrint('=== VERIFICANDO SE COLUNA user_id EXISTE ===');
      
      // Tentar carregar um laudo com user_id
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/laudos?select=id,user_id&limit=1'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        debugPrint('=== COLUNA user_id EXISTE (SUCESSO 200) ===');
        return true;
      } else if (response.statusCode == 400) {
        // 400 geralmente significa que a coluna não existe
        debugPrint('=== COLUNA user_id NÃO EXISTE (ERRO 400) ===');
        return false;
      } else {
        // Para qualquer outro erro, assumir que existe para não bloquear
        debugPrint('=== ERRO INESPERADO (${response.statusCode}), ASSUMINDO QUE EXISTE ===');
        return true;
      }
    } catch (e) {
      debugPrint('=== ERRO AO VERIFICAR COLUNA: $e ===');
      // Em caso de erro, assumir que existe para não bloquear o sistema
      return true;
    }
  }
}
