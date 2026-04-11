import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

class LaudosGlobalService {
  static const String _laudosKey = 'laudos_cadastrados';
  static const String _auditoriasKey = 'auditorias_todos';
  
  // Obter chave específica do usuário
  static String _getUserLaudosKey() {
    final currentUser = AuthService.currentUser;
    if (currentUser != null) {
      return '${_laudosKey}_${currentUser.uid}';
    }
    return _laudosKey;
  }
  
  // Obter chave para auditorias (sempre a mesma, não por usuário)
  static String _getAuditoriasKey() {
    return _auditoriasKey;
  }

  // Carregar TODOS os laudos do Supabase (visão global para todos os usuários)
  static Future<List<Map<String, dynamic>>> carregarTodosLaudos() async {
    try {
      debugPrint('=== CARREGANDO TODOS OS LAUDOS DO SUPABASE (AUDITORIAS) ===');
      
      // Carregar do Supabase sem filtrar por usuário
      final laudosSupabase = await SupabaseService.carregarTodosLaudos();
      
      if (laudosSupabase.isNotEmpty) {
        debugPrint('=== ${laudosSupabase.length} LAUDOS CARREGADOS DO SUPABASE (VISÃO DE AUDITORIA) ===');
        
        // NÃO SALVAR localmente para evitar misturar com laudos do usuário
        // Retornar diretamente do Supabase sem cache
        return laudosSupabase;
      }
      
      debugPrint('=== NENHUM LAUDO NO SUPABASE ===');
      return [];
      
    } catch (e) {
      debugPrint('Erro ao carregar todos os laudos: $e');
      debugPrint('=== FALLBACK: RETORNANDO LISTA VAZIA ===');
      // Em caso de erro, retornar lista vazia para não misturar dados
      return [];
    }
  }

  // Carregar APENAS os laudos do usuário atual (visão pessoal)
  static Future<List<Map<String, dynamic>>> carregarLaudosUsuario() async {
    try {
      debugPrint('=== CARREGANDO LAUDOS DO USUÁRIO - PRIORIDADE LOCAL ===');
      
      // 1. CARREGAR PRIMEIRO DO STORAGE LOCAL (dados mais recentes)
      final laudosLocais = await _carregarLaudosLocal();
      debugPrint('=== ${laudosLocais.length} LAUDOS CARREGADOS DO STORAGE LOCAL ===');
      
      if (laudosLocais.isNotEmpty) {
        debugPrint('=== USANDO DADOS LOCAIS (SÃO OS MAIS RECENTES) ===');
        return laudosLocais;
      }
      
      debugPrint('=== STORAGE LOCAL VAZIO, CARREGANDO DO SUPABASE ===');
      
      // 2. Se local estiver vazio, carregar do Supabase
      final laudosSupabase = await SupabaseService.carregarLaudos();
      
      if (laudosSupabase.isNotEmpty) {
        debugPrint('=== ${laudosSupabase.length} LAUDOS DO SUPABASE CARREGADOS ===');
        
        // Filtrar por usuário
        final currentUser = AuthService.currentUser;
        if (currentUser != null) {
          final laudosFiltrados = laudosSupabase.where((laudo) {
            final userIdLaudo = laudo['user_id']?.toString();
            return userIdLaudo == currentUser.uid || userIdLaudo == null;
          }).toList();
          
          debugPrint('=== ${laudosFiltrados.length} LAUDOS FILTRADOS POR USUÁRIO ===');
          
          // Salvar localmente para cache
          await _salvarLaudosLocal(laudosFiltrados);
          return laudosFiltrados;
        }
        
        await _salvarLaudosLocal(laudosSupabase);
        return laudosSupabase;
      }
      
      debugPrint('=== NENHUM LAUDO ENCONTRADO ===');
      return [];
      
    } catch (e) {
      debugPrint('Erro ao carregar laudos do usuário: $e');
      debugPrint('=== FALLBACK: CARREGANDO LAUDOS LOCAIS ===');
      // Fallback para dados locais
      return await _carregarLaudosLocal();
    }
  }

  // Métodos locais auxiliares
  static Future<List<Map<String, dynamic>>> _carregarLaudosLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserLaudosKey();
      final laudosJson = prefs.getString(userKey) ?? '[]';
      
      final List<dynamic> laudosList = json.decode(laudosJson);
      final laudos = laudosList.cast<Map<String, dynamic>>();
      
      debugPrint('=== ${laudos.length} LAUDOS DO USUÁRIO CARREGADOS DO STORAGE LOCAL (CHAVE: $userKey) ===');
      return laudos;
    } catch (e) {
      debugPrint('Erro ao carregar laudos do storage local: $e');
      return [];
    }
  }

  static Future<void> _salvarLaudosLocal(List<Map<String, dynamic>> laudos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userKey = _getUserLaudosKey();
      final laudosJson = json.encode(laudos);
      await prefs.setString(userKey, laudosJson);
      debugPrint('=== ${laudos.length} LAUDOS DO USUÁRIO SALVOS NO STORAGE LOCAL (CHAVE: $userKey) ===');
    } catch (e) {
      debugPrint('Erro ao salvar laudos no storage local: $e');
    }
  }
  
  // Método específico para auditorias (não salva cache local)
  static Future<List<Map<String, dynamic>>> _carregarAuditoriasLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auditoriasKey = _getAuditoriasKey();
      final laudosJson = prefs.getString(auditoriasKey) ?? '[]';
      
      final List<dynamic> laudosList = json.decode(laudosJson);
      final laudos = laudosList.cast<Map<String, dynamic>>();
      
      debugPrint('=== ${laudos.length} AUDITORIAS CARREGADAS DO STORAGE LOCAL (CHAVE: $auditoriasKey) ===');
      return laudos;
    } catch (e) {
      debugPrint('Erro ao carregar auditorias do storage local: $e');
      return [];
    }
  }
  
  static Future<void> _salvarAuditoriasLocal(List<Map<String, dynamic>> laudos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auditoriasKey = _getAuditoriasKey();
      final laudosJson = json.encode(laudos);
      await prefs.setString(auditoriasKey, laudosJson);
      debugPrint('=== ${laudos.length} AUDITORIAS SALVAS NO STORAGE LOCAL (CHAVE: $auditoriasKey) ===');
    } catch (e) {
      debugPrint('Erro ao salvar auditorias no storage local: $e');
    }
  }
}
