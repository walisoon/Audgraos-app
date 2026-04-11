import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'supabase_service.dart';

class StorageService {
  static const String _ordensServicoKey = 'ordens_servico';
  static const String _laudosKey = 'laudos';
  static const String _clientesKey = 'clientes';
  static const String _auditoriasKey = 'auditorias';
  static const String _relatoriosKey = 'relatorios';

  // Salvar ordens de serviço
  static Future<void> salvarOrdensServico(List<Map<String, dynamic>> ordens) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordensJson = jsonEncode(ordens);
      await prefs.setString(_ordensServicoKey, ordensJson);
    } catch (e) {
      print('Erro ao salvar ordens de serviço: $e');
    }
  }

  // Carregar ordens de serviço
  static Future<List<Map<String, dynamic>>> carregarOrdensServico() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordensJson = prefs.getString(_ordensServicoKey);
      
      if (ordensJson != null) {
        final List<dynamic> ordensList = jsonDecode(ordensJson);
        return ordensList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao carregar ordens de serviço: $e');
      return [];
    }
  }

  // Adicionar uma nova ordem de serviço
  static Future<void> adicionarOrdemServico(Map<String, dynamic> ordem) async {
    try {
      final ordens = await carregarOrdensServico();
      ordens.add(ordem);
      await salvarOrdensServico(ordens);
    } catch (e) {
      print('Erro ao adicionar ordem de serviço: $e');
    }
  }

  // Salvar laudos
  static Future<void> salvarLaudos(List<Map<String, dynamic>> laudos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final laudosJson = jsonEncode(laudos);
      await prefs.setString(_laudosKey, laudosJson);
    } catch (e) {
      print('Erro ao salvar laudos: $e');
    }
  }

  // Carregar laudos
  static Future<List<Map<String, dynamic>>> carregarLaudos() async {
    try {
      debugPrint('=== STORAGE: CARREGANDO LAUDOS DO SUPABASE ===');
      // Tentar buscar do Supabase primeiro
      final laudosSupabase = await SupabaseService.buscarLaudos();
      debugPrint('=== STORAGE: LAUDOS DO SUPABASE: ${laudosSupabase.length} ===');
      if (laudosSupabase.isNotEmpty) {
        debugPrint('=== STORAGE: USANDO DADOS DO SUPABASE ===');
        return laudosSupabase;
      }
      
      debugPrint('=== STORAGE: SUPABASE VAZIO, USANDO STORAGE LOCAL ===');
      // Fallback para storage local
      final prefs = await SharedPreferences.getInstance();
      final laudosJson = prefs.getString(_laudosKey);
      
      if (laudosJson != null) {
        final List<dynamic> laudosList = jsonDecode(laudosJson);
        debugPrint('=== STORAGE: LAUDOS LOCAIS: ${laudosList.length} ===');
        return laudosList.cast<Map<String, dynamic>>();
      }
      debugPrint('=== STORAGE: NENHUM LAUDO ENCONTRADO ===');
      return [];
    } catch (e) {
      debugPrint('=== STORAGE: ERRO AO CARREGAR LAUDOS: $e ===');
      // Fallback para storage local
      try {
        final prefs = await SharedPreferences.getInstance();
        final laudosJson = prefs.getString(_laudosKey);
        
        if (laudosJson != null) {
          final List<dynamic> laudosList = jsonDecode(laudosJson);
          debugPrint('=== STORAGE: FALLBACK LOCAL: ${laudosList.length} LAUDOS ===');
          return laudosList.cast<Map<String, dynamic>>();
        }
      } catch (localError) {
        debugPrint('=== STORAGE: ERRO NO FALLBACK LOCAL: $localError ===');
      }
      return [];
    }
  }

  // Gerar próximo ID do laudo (começando do 282)
  static Future<String> _gerarProximoIdLaudo() async {
    try {
      final laudos = await carregarLaudos();
      
      if (laudos.isEmpty) {
        return '00282'; // Primeiro laudo
      }
      
      // Encontrar o maior ID existente
      int maiorId = 281; // Começar do 281 para o próximo ser 282
      for (final laudo in laudos) {
        final idStr = laudo['id']?.toString() ?? '00000';
        final id = int.tryParse(idStr) ?? 281;
        if (id > maiorId) {
          maiorId = id;
        }
      }
      
      // Gerar próximo ID com 5 dígitos
      final proximoId = maiorId + 1;
      return proximoId.toString().padLeft(5, '0');
    } catch (e) {
      print('Erro ao gerar próximo ID: $e');
      return '00282'; // ID padrão em caso de erro
    }
  }

  // Adicionar um novo laudo
  static Future<void> adicionarLaudo(Map<String, dynamic> laudo) async {
    try {
      debugPrint('=== STORAGE: ADICIONANDO LAUDO ===');
      
      // Gerar ID automático se não existir
      if (laudo['id'] == null || laudo['id'].toString().isEmpty) {
        laudo['id'] = await _gerarProximoIdLaudo();
        debugPrint('ID gerado automaticamente: ${laudo['id']}');
      }
      
      // Tentar salvar no Supabase primeiro
      try {
        await SupabaseService.adicionarLaudo(laudo);
        debugPrint('Laudo salvo no Supabase: ${laudo['id']}');
        laudo['sincronizado'] = true;
      } catch (supabaseError) {
        debugPrint('Erro ao salvar no Supabase, usando fallback local: $supabaseError');
        // Fallback para storage local
        final laudos = await carregarLaudos();
        laudo['sincronizado'] = false;
        laudos.add(laudo);
        await salvarLaudos(laudos);
        debugPrint('Laudo salvo localmente: ${laudo['id']}');
      }
    } catch (e) {
      debugPrint('Erro ao adicionar laudo: $e');
      throw e;
    }
  }

  // Salvar clientes
  static Future<void> salvarClientes(List<Map<String, dynamic>> clientes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientesJson = jsonEncode(clientes);
      await prefs.setString(_clientesKey, clientesJson);
    } catch (e) {
      print('Erro ao salvar clientes: $e');
    }
  }

  // Carregar clientes
  static Future<List<Map<String, dynamic>>> carregarClientes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientesJson = prefs.getString(_clientesKey);
      
      if (clientesJson != null) {
        final List<dynamic> clientesList = jsonDecode(clientesJson);
        return clientesList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao carregar clientes: $e');
      return [];
    }
  }

  // Adicionar um novo cliente
  static Future<void> adicionarCliente(Map<String, dynamic> cliente) async {
    try {
      final clientes = await carregarClientes();
      clientes.add(cliente);
      await salvarClientes(clientes);
    } catch (e) {
      print('Erro ao adicionar cliente: $e');
    }
  }

  // Atualizar um cliente
  static Future<void> atualizarCliente(String id, Map<String, dynamic> clienteAtualizado) async {
    try {
      final clientes = await carregarClientes();
      final index = clientes.indexWhere((cliente) => cliente['id'] == id);
      
      if (index != -1) {
        clientes[index] = clienteAtualizado;
        await salvarClientes(clientes);
      }
    } catch (e) {
      print('Erro ao atualizar cliente: $e');
    }
  }

  // Excluir um cliente
  static Future<void> excluirCliente(String id) async {
    try {
      final clientes = await carregarClientes();
      clientes.removeWhere((cliente) => cliente['id'] == id);
      await salvarClientes(clientes);
    } catch (e) {
      print('Erro ao excluir cliente: $e');
    }
  }

  // Excluir um laudo
  static Future<void> excluirLaudo(String id) async {
    try {
      final laudos = await carregarLaudos();
      laudos.removeWhere((laudo) => laudo['id'] == id);
      await salvarLaudos(laudos);
    } catch (e) {
      print('Erro ao excluir laudo: $e');
    }
  }

  // Atualizar um laudo existente
  static Future<void> atualizarLaudo(String id, Map<String, dynamic> laudoAtualizado) async {
    try {
      debugPrint('=== STORAGE: ATUALIZANDO LAUDO ===');
      debugPrint('ID do laudo: $id');
      debugPrint('Dados atualizados: $laudoAtualizado');
      
      final laudos = await carregarLaudos();
      debugPrint('Total de laudos antes: ${laudos.length}');
      
      // Encontrar o índice do laudo
      final index = laudos.indexWhere((laudo) => laudo['id'].toString() == id);
      
      if (index != -1) {
        // Atualizar o laudo existente
        laudos[index] = laudoAtualizado;
        await salvarLaudos(laudos);
        debugPrint('Laudo atualizado com sucesso! Total após: ${laudos.length}');
      } else {
        debugPrint('Laudo não encontrado para atualização. ID: $id');
        throw Exception('Laudo não encontrado');
      }
    } catch (e) {
      debugPrint('Erro ao atualizar laudo: $e');
      rethrow;
    }
  }

  // Limpar todos os dados (para testes)
  static Future<void> limparDados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ordensServicoKey);
      await prefs.remove(_laudosKey);
      await prefs.remove(_clientesKey);
    } catch (e) {
      print('Erro ao limpar dados: $e');
    }
  }

  // Obter estatísticas
  static Future<Map<String, int>> obterEstatisticas() async {
    try {
      final ordens = await carregarOrdensServico();
      final laudos = await carregarLaudos();
      final clientes = await carregarClientes();
      
      return {
        'totalOrdens': ordens.length,
        'totalLaudos': laudos.length,
        'totalClientes': clientes.length,
        'ordensPendentes': ordens.where((o) => o['status'] == 'pendente').length,
        'ordensEmAndamento': ordens.where((o) => o['status'] == 'em_andamento').length,
        'ordensConcluidas': ordens.where((o) => o['status'] == 'concluida').length,
      };
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {};
    }
  }

  // Gerar PDF do laudo
  static Future<void> gerarPdfLaudo(Map<String, dynamic> laudo) async {
    try {
      final pdf = pw.Document();
      
      // Carregar fontes
      final font = await PdfGoogleFonts.nunitoRegular();
      final fontBold = await PdfGoogleFonts.nunitoBold();
      
      // Adicionar página ao PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AUDGRÃOS',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 24,
                            color: PdfColors.green800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Sistema de Auditoria de Grãos',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 12,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Text(
                      'LAUDO DE AUDITORIA',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 18,
                        color: PdfColors.black,
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 24),
                
                // Linha separadora
                pw.Divider(color: PdfColors.grey300),
                
                pw.SizedBox(height: 20),
                
                // Informações do Laudo
                _buildSection('Informações do Laudo', [
                  _buildInfoRow('ID do Laudo:', laudo['id'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Serviço:', laudo['servico'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Data:', laudo['data'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Status:', laudo['status'] ?? 'N/A', font, fontBold),
                ], font, fontBold),
                
                pw.SizedBox(height: 20),
                
                // Dados da Auditoria
                _buildSection('Dados da Auditoria', [
                  _buildInfoRow('Origem:', laudo['origem'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Destino:', laudo['destino'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Nota Fiscal:', laudo['notaFiscal'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Produto:', laudo['produto'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Cliente:', laudo['cliente'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Placa do Veículo:', laudo['placa'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Certificadora Responsável:', laudo['certificadora'] ?? 'N/A', font, fontBold),
                ], font, fontBold),
                
                pw.SizedBox(height: 20),
                
                // Divergência Identificada
                _buildSection('Divergência Identificada', [
                  _buildInfoRow('Tipo:', laudo['tipo'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Descrição:', laudo['divergencia'] ?? 'N/A', font, fontBold),
                ], font, fontBold),
                
                pw.SizedBox(height: 20),
                
                // Resultados
                _buildSection('Resultados', [
                  _buildInfoRow('Terminal Recusa:', laudo['terminalRecusa'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Resultado Auditoria:', laudo['resultado'] ?? 'N/A', font, fontBold),
                ], font, fontBold),
                
                pw.SizedBox(height: 20),
                
                // Análises
                _buildSection('Análises', [
                  _buildInfoRow('Odor:', laudo['odor'] ?? 'N/A', font, fontBold),
                  _buildInfoRow('Sementes:', laudo['sementes'] ?? 'N/A', font, fontBold),
                ], font, fontBold),
                
                pw.SizedBox(height: 20),
                
                // Observações
                if (laudo['observacoes'] != null && laudo['observacoes'].toString().isNotEmpty) ...[
                  _buildSection('Observações', [
                    pw.Text(
                      laudo['observacoes'].toString(),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColors.black,
                      ),
                    ),
                  ], font, fontBold),
                ],
                
                pw.SizedBox(height: 40),
                
                // Rodapé
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Column(
                    children: [
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Laudo gerado em ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} às ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '© 2024 Audgrãos - Sistema de Auditoria de Grãos',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Salvar PDF
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/laudo_${laudo['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      // Imprimir ou compartilhar
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laudo_${laudo['id']}',
      );
      
    } catch (e) {
      print('Erro ao gerar PDF: $e');
    }
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> children, pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 14,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 11,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  static Future<void> inicializarDadosExemplo() async {
    try {
      print('Aplicativo iniciado sem dados de exemplo');
    } catch (e) {
      print('Erro ao inicializar dados: $e');
    }
  }

  // ====== AUDITORIAS E RELATÓRIOS ======

  // Salvar auditorias
  static Future<void> salvarAuditorias(List<Map<String, dynamic>> auditorias) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final auditoriasJson = jsonEncode(auditorias);
      await prefs.setString(_auditoriasKey, auditoriasJson);
      print('Auditorias salvas: ${auditorias.length}');
    } catch (e) {
      print('Erro ao salvar auditorias: $e');
    }
  }

  // Carregar auditorias
  static Future<List<Map<String, dynamic>>> carregarAuditorias() async {
    try {
      // Tentar buscar do Supabase primeiro
      final auditoriasSupabase = await SupabaseService.buscarAuditorias();
      if (auditoriasSupabase.isNotEmpty) {
        return auditoriasSupabase;
      }
      
      // Fallback para storage local
      final prefs = await SharedPreferences.getInstance();
      final auditoriasJson = prefs.getString(_auditoriasKey);
      
      if (auditoriasJson != null) {
        final List<dynamic> auditoriasList = jsonDecode(auditoriasJson);
        return auditoriasList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao carregar auditorias: $e');
      // Fallback para storage local
      try {
        final prefs = await SharedPreferences.getInstance();
        final auditoriasJson = prefs.getString(_auditoriasKey);
        
        if (auditoriasJson != null) {
          final List<dynamic> auditoriasList = jsonDecode(auditoriasJson);
          return auditoriasList.cast<Map<String, dynamic>>();
        }
      } catch (localError) {
        print('Erro no fallback local: $localError');
      }
      return [];
    }
  }

  // Adicionar nova auditoria
  static Future<void> adicionarAuditoria(Map<String, dynamic> auditoria) async {
    try {
      // Tentar salvar no Supabase primeiro
      await SupabaseService.adicionarAuditoria(auditoria);
      print('Auditoria salva no Supabase: ${auditoria['codigo']}');
    } catch (e) {
      print('Erro ao salvar no Supabase, usando fallback local: $e');
      // Fallback para storage local
      try {
        final auditorias = await carregarAuditorias();
        auditorias.add(auditoria);
        await salvarAuditorias(auditorias);
      } catch (localError) {
        print('Erro no fallback local: $localError');
        throw localError;
      }
    }
  }

  // Salvar relatórios
  static Future<void> salvarRelatorios(List<Map<String, dynamic>> relatorios) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final relatoriosJson = jsonEncode(relatorios);
      await prefs.setString(_relatoriosKey, relatoriosJson);
      print('Relatórios salvos: ${relatorios.length}');
    } catch (e) {
      print('Erro ao salvar relatórios: $e');
    }
  }

  // Carregar relatórios
  static Future<List<Map<String, dynamic>>> carregarRelatorios() async {
    try {
      // Tentar buscar do Supabase primeiro
      final relatoriosSupabase = await SupabaseService.buscarRelatorios();
      if (relatoriosSupabase.isNotEmpty) {
        return relatoriosSupabase;
      }
      
      // Fallback para storage local
      final prefs = await SharedPreferences.getInstance();
      final relatoriosJson = prefs.getString(_relatoriosKey);
      
      if (relatoriosJson != null) {
        final List<dynamic> relatoriosList = jsonDecode(relatoriosJson);
        return relatoriosList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Erro ao carregar relatórios: $e');
      // Fallback para storage local
      try {
        final prefs = await SharedPreferences.getInstance();
        final relatoriosJson = prefs.getString(_relatoriosKey);
        
        if (relatoriosJson != null) {
          final List<dynamic> relatoriosList = jsonDecode(relatoriosJson);
          return relatoriosList.cast<Map<String, dynamic>>();
        }
      } catch (localError) {
        print('Erro no fallback local: $localError');
      }
      return [];
    }
  }

  // Gerar relatório de auditoria
  static Future<void> gerarRelatorioAuditoria(Map<String, dynamic> auditoria) async {
    try {
      final relatorios = await carregarRelatorios();
      
      // Criar relatório
      final relatorio = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'auditoria_codigo': auditoria['codigo'],
        'auditoria_titulo': auditoria['titulo'],
        'auditor': auditoria['auditor'],
        'data_geracao': DateTime.now().toIso8601String(),
        'tipo': 'auditoria',
        'status': auditoria['status'],
        'pontuacao': auditoria['pontuacao'],
        'nao_conformidades': auditoria['naoConformidades'],
        'area': auditoria['area'],
        'findings': auditoria['findings'] ?? [],
        'recomendacoes': auditoria['recomendacoes'] ?? [],
      };
      
      relatorios.add(relatorio);
      await salvarRelatorios(relatorios);
      
      print('Relatório gerado para auditoria: ${auditoria['codigo']}');
    } catch (e) {
      print('Erro ao gerar relatório: $e');
    }
  }

  // Gerar relatório de laudo (lançamento de auditoria)
  static Future<void> gerarRelatorioLaudo(Map<String, dynamic> laudo) async {
    try {
      final relatorios = await carregarRelatorios();
      
      // Lógica de status baseada no campo resultado
      String statusLaudo;
      if (laudo['resultado'] == null || 
          laudo['resultado'].toString().trim().isEmpty) {
        statusLaudo = 'em_andamento';
      } else {
        statusLaudo = 'concluida';
      }
      
      // Criar lançamento de auditoria a partir do laudo
      final lancamento = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'laudo_id': laudo['id'],
        'laudo_servico': laudo['servico'],
        'laudo_data': laudo['data'],
        'laudo_status': statusLaudo,
        'auditoria_codigo': 'LAUDO-${laudo['id']}',
        'auditoria_titulo': 'Laudo: ${laudo['servico']}',
        'auditor': laudo['auditor'] ?? 'Usuário',
        'data_geracao': DateTime.now().toIso8601String(),
        'tipo': 'laudo_auditoria',
        'status': statusLaudo,
        'pontuacao': laudo['pontuacao'] ?? 0.0,
        'nao_conformidades': laudo['naoConformidades'] ?? 0,
        'area': laudo['area'] ?? 'Laudo',
        'findings': laudo['findings'] ?? ['Laudo gerado pelo usuário'],
        'recomendacoes': laudo['recomendacoes'] ?? ['Analisar laudo detalhadamente'],
        'descricao': 'Lançamento automático a partir do laudo ${laudo['id']}',
        'data_lancamento': DateTime.now().toIso8601String(),
        'usuario': 'sistema',
      };
      
      relatorios.add(lancamento);
      await salvarRelatorios(relatorios);
      
      print('Lançamento de auditoria gerado a partir do laudo: ${laudo['id']}');
    } catch (e) {
      print('Erro ao gerar lançamento de laudo: $e');
    }
  }

  // Adicionar lançamento (para todos os usuários)
  static Future<void> adicionarLancamento(Map<String, dynamic> lancamento) async {
    try {
      // Tentar salvar no Supabase primeiro
      await SupabaseService.adicionarRelatorio(lancamento);
      print('Lançamento salvo no Supabase: ${lancamento['id']}');
    } catch (e) {
      print('Erro ao salvar no Supabase, usando fallback local: $e');
      // Fallback para storage local
      try {
        final relatorios = await carregarRelatorios();
        
        // Criar lançamento com ID único
        final lancamentoComId = {
          ...lancamento,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'data_lancamento': DateTime.now().toIso8601String(),
          'usuario': 'sistema', // Pode ser alterado para usuário atual
        };
        
        relatorios.add(lancamentoComId);
        await salvarRelatorios(relatorios);
        print('Lançamento salvo localmente: ${lancamentoComId['id']}');
      } catch (localError) {
        print('Erro no fallback local: $localError');
        throw localError;
      }
    }
  }
}
