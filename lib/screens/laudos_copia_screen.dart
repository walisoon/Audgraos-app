import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'classificacao_laudo_screen.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../services/laudos_service.dart';
import '../services/laudos_global_service.dart';

// Timestamp para forçar reload
final String _buildVersion = 'v2.1-${DateTime.now().millisecondsSinceEpoch}';

class LaudosCopiaScreen extends StatefulWidget {
  const LaudosCopiaScreen({super.key});

  // Instância estática para acesso global
  static _LaudosCopiaScreenState? _instance;

  static void adicionarLaudo(Map<String, dynamic> laudo) {
    _instance?._adicionarLaudo(laudo);
  }

  static void atualizarLista() {
    _instance?._carregarLaudosSalvos();
  }
  
  static void atualizarLaudo(Map<String, dynamic> laudo) {
    _instance?._atualizarLaudoNaLista(laudo);
  }

  @override
  State<LaudosCopiaScreen> createState() {
    final state = _LaudosCopiaScreenState();
    _instance = state;
    return state;
  }
}

class _LaudosCopiaScreenState extends State<LaudosCopiaScreen> {
  List<Map<String, dynamic>> _laudos = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _laudosFiltrados = <Map<String, dynamic>>[];
  bool _carregando = false;
  
  // Controles de filtro
  String _filtroStatus = 'todos'; // todos, concluidos, em_andamento
  String _filtroAuditor = 'todos'; // todos, motorista1, motorista2, etc.
  DateTime? _filtroDataInicio;
  DateTime? _filtroDataFim;

  @override
  void initState() {
    super.initState();
    _carregarLaudosSalvos();
  }

  Future<void> _carregarLaudosSalvos() async {
    setState(() {
      _carregando = true;
    });
    
    try {
      debugPrint('=== CARREGANDO AUDITORIAS - MODO SUPABASE EXCLUSIVO ===');
      debugPrint('📊 PÁGINA AUDITORIAS: MODO SUPABASE APENAS (SEM DADOS LOCAIS)');
      
      // Carregar APENAS do Supabase (dados de todos os usuários)
      final laudos = await LaudosGlobalService.carregarTodosLaudos();
      debugPrint('✅ Laudos do Supabase carregados: ${laudos.length}');
      
      setState(() {
        _laudos = laudos;
        _aplicarFiltros();
        _carregando = false;
      });
      
      debugPrint('✅ Estado atualizado com ${_laudos.length} laudos (MODO SUPABASE)');
    } catch (e) {
      debugPrint('Erro ao carregar laudos do Supabase: $e');
      setState(() {
        _carregando = false;
        _laudos = []; // Lista vazia se falhar
      });
    }
  }

  void _aplicarFiltros() {
    _laudosFiltrados = List.from(_laudos);
    
    // Filtro por status
    if (_filtroStatus != 'todos') {
      if (_filtroStatus == 'concluidos') {
        _laudosFiltrados = _laudosFiltrados.where((laudo) {
          final resultado = laudo['resultado']?.toString().trim() ?? '';
          return resultado.isNotEmpty;
        }).toList();
      } else if (_filtroStatus == 'em_andamento') {
        _laudosFiltrados = _laudosFiltrados.where((laudo) {
          final resultado = laudo['resultado']?.toString().trim() ?? '';
          return resultado.isEmpty;
        }).toList();
      }
    }
    
    // Filtro por cliente
    if (_filtroAuditor != 'todos') {
      _laudosFiltrados = _laudosFiltrados.where((laudo) {
        final cliente = laudo['cliente']?.toString().toLowerCase() ?? '';
        return cliente.contains(_filtroAuditor.toLowerCase());
      }).toList();
    }
    
    // Filtro por data
    if (_filtroDataInicio != null) {
      _laudosFiltrados = _laudosFiltrados.where((laudo) {
        final dataLaudo = DateTime.tryParse(laudo['data'] ?? '');
        if (dataLaudo == null) return false;
        return dataLaudo.isAfter(_filtroDataInicio!.subtract(const Duration(days: 1)));
      }).toList();
    }
    
    if (_filtroDataFim != null) {
      _laudosFiltrados = _laudosFiltrados.where((laudo) {
        final dataLaudo = DateTime.tryParse(laudo['data'] ?? '');
        if (dataLaudo == null) return false;
        return dataLaudo.isBefore(_filtroDataFim!.add(const Duration(days: 1)));
      }).toList();
    }
    
    debugPrint('=== FILTROS APLICADOS ===');
    debugPrint('Status: $_filtroStatus');
    debugPrint('Cliente: $_filtroAuditor');
    debugPrint('Data Início: $_filtroDataInicio');
    debugPrint('Data Fim: $_filtroDataFim');
    debugPrint('Resultados: ${_laudosFiltrados.length}/${_laudos.length}');
  }

  List<DropdownMenuItem<String>> _getAuditoresOptions() {
    final auditores = <String>{'todos'};
    
    // Coletar todos os motoristas únicos dos laudos
    for (var laudo in _laudos) {
      final motorista = laudo['motorista']?.toString();
      if (motorista != null && motorista.isNotEmpty) {
        auditores.add(motorista);
      }
    }
    
    // Converter para DropdownMenuItem
    return auditores.map((auditor) {
      return DropdownMenuItem<String>(
        value: auditor,
        child: Text(auditor == 'todos' ? 'Todos' : auditor),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _getAuditoresOptionsCompact() {
    final auditores = <String>{'todos'};
    
    // Coletar todos os motoristas únicos dos laudos
    for (var laudo in _laudos) {
      final motorista = laudo['motorista']?.toString();
      if (motorista != null && motorista.isNotEmpty) {
        auditores.add(motorista);
      }
    }
    
    // Converter para DropdownMenuItem compacto
    return auditores.map((auditor) {
      return DropdownMenuItem<String>(
        value: auditor,
        child: Text(
          auditor == 'todos' ? 'Auditor' : auditor.length > 10 ? '${auditor.substring(0, 10)}...' : auditor,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _getClientesOptionsCompact() {
    final clientes = <String>{'todos'};
    
    // Coletar todos os clientes únicos dos laudos
    for (var laudo in _laudos) {
      final cliente = laudo['cliente']?.toString();
      if (cliente != null && cliente.isNotEmpty) {
        clientes.add(cliente);
      }
    }
    
    // Converter para DropdownMenuItem compacto
    return clientes.map((cliente) {
      return DropdownMenuItem<String>(
        value: cliente,
        child: Text(
          cliente == 'todos' ? 'Cliente' : cliente.length > 10 ? '${cliente.substring(0, 10)}...' : cliente,
          style: const TextStyle(fontSize: 11),
        ),
      );
    }).toList();
  }

  void _adicionarLaudo(Map<String, dynamic> laudo) async {
    try {
      // Adicionar usando LaudosService (com sincronização)
      await LaudosService.adicionarLaudo(laudo);
      
      // Recarregar lista para pegar dados atualizados
      await _carregarLaudosSalvos();
      
      // Forçar atualização da UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Erro ao adicionar laudo: $e');
      // Mesmo com erro, tentar recarregar para mostrar dados locais
      await _carregarLaudosSalvos();
      if (mounted) {
        setState(() {});
      }
    }
  }
  
  void _atualizarLaudoNaLista(Map<String, dynamic> laudo) {
    try {
      debugPrint('=== ATUALIZANDO LAUDO NA LISTA DE AUDITORIAS ===');
      debugPrint('Laudo: ${laudo['numero_laudo']}');
      
      // Encontrar o índice do laudo existente
      final existingIndex = _laudos.indexWhere(
        (l) => l['id'].toString() == laudo['id'].toString()
      );
      
      if (existingIndex != -1) {
        // Atualizar laudo existente
        _laudos[existingIndex] = laudo;
        debugPrint('✅ Laudo atualizado na lista de auditorias: ${laudo['numero_laudo']}');
      } else {
        // Adicionar novo laudo
        _laudos.add(laudo);
        debugPrint('✅ Novo laudo adicionado à lista de auditorias: ${laudo['numero_laudo']}');
      }
      
      // Aplicar filtros e atualizar estado
      _aplicarFiltros();
      
      if (mounted) {
        setState(() {});
      }
      
      debugPrint('=== LISTA DE AUDITORIAS ATUALIZADA COM SUCESSO ===');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar laudo na lista de auditorias: $e');
    }
  }

  Future<void> _excluirLaudo(Map<String, dynamic> laudo) async {
    // Confirmar exclusão
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Confirmar Exclusão',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Deseja realmente excluir o laudo ${laudo['id']}?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF63b14a),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      try {
        // Remover usando LaudosService (com sincronização)
        await LaudosService.excluirLaudo(laudo['id'], numeroLaudo: laudo['numero_laudo']?.toString());
        
        // Recarregar lista para pegar dados atualizados
        await _carregarLaudosSalvos();
        
        // Forçar atualização da UI
        if (mounted) {
          setState(() {});
        }
        
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.delete, color: Colors.white),
                SizedBox(width: 8),
                Text('Laudo excluído com sucesso!'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('❌ Erro ao excluir laudo: $e');
        // Mesmo com erro, tentar recarregar para mostrar dados atualizados
        await _carregarLaudosSalvos();
        if (mounted) {
          setState(() {});
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao excluir laudo. Tente novamente.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _gerarPdfLaudo(Map<String, dynamic> laudo) async {
    try {
      await StorageService.gerarPdfLaudo(laudo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF gerado com sucesso!'),
          backgroundColor: Color(0xFF63b14a),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao gerar PDF'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _novoLaudo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClassificacaoLaudoScreen(
          ordemNumero: '',
          servico: '',
        ),
      ),
    );
  }

  void _gerarHtmlParaImpressao(Map<String, dynamic> laudo) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Laudo de Clientes - AGROCLASS MOBILE</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { text-align: center; border-bottom: 3px solid #63b14a; padding-bottom: 20px; margin-bottom: 30px; }
        .logo { color: #63b14a; font-size: 28px; font-weight: bold; }
        .subtitle { color: #666; font-size: 14px; }
        .section { margin: 20px 0; padding: 20px; border: 2px solid #63b14a; border-radius: 10px; }
        .section-title { color: #63b14a; font-size: 16px; font-weight: bold; margin-bottom: 15px; }
        .info-row { margin: 8px 0; display: flex; }
        .label { font-weight: bold; width: 120px; }
        .value { flex: 1; }
        .result-section { background: #E3F2FD; border-color: #2196F3; }
        .footer { margin-top: 40px; text-align: center; color: #666; font-size: 12px; border-top: 1px solid #63b14a; padding-top: 20px; }
        @media print { body { margin: 20px; } }
    </style>
</head>
<body>
    <div class="header">
        <div class="logo">AGROCLASS MOBILE</div>
        <div class="subtitle">Sistema de Clientes de Grãos</div>
        <div style="margin-top: 10px; border: 2px solid #63b14a; padding: 10px; display: inline-block; border-radius: 8px;">
            <div style="font-size: 10px; font-weight: bold; color: #63b14a;">LAUDO DE</div>
            <div style="font-size: 14px; font-weight: bold; color: #63b14a;">CLIENTES</div>
        </div>
    </div>
    
    <div class="section">
        <div class="section-title">DADOS DA ORDEM DE SERVIÇO</div>
        <div class="info-row"><span class="label">OS:</span> <span class="value">${laudo['id'] ?? 'N/A'}</span></div>
        <div class="info-row"><span class="label">Data:</span> <span class="value">${laudo['data'] ?? 'N/A'}</span></div>
        <div class="info-row"><span class="label">Serviço:</span> <span class="value">${laudo['servico'] ?? 'N/A'}</span></div>
        <div class="info-row"><span class="label">Status:</span> <span class="value">${laudo['status'] ?? 'N/A'}</span></div>
    </div>
    
    ${laudo.containsKey('placa') || laudo.containsKey('peso') ? '''
    <div class="section">
        <div class="section-title">INFORMAÇÕES DE TRANSPORTE</div>
        ${laudo.containsKey('placa') ? '<div class="info-row"><span class="label">Placa:</span> <span class="value">${laudo['placa'] ?? 'N/A'}</span></div>' : ''}
        ${laudo.containsKey('peso') ? '<div class="info-row"><span class="label">Peso:</span> <span class="value">${laudo['peso'] ?? 'N/A'}</span></div>' : ''}
    </div>
    ''' : ''}
    
    <div class="section result-section">
        <div class="section-title">RESULTADOS DOS CLIENTES</div>
        <div class="info-row"><span class="label">Umidade:</span> <span class="value">${laudo['umidade'] ?? 'N/A'}</span></div>
        <div class="info-row"><span class="label">Mat. Estranhas:</span> <span class="value">${laudo['materiasEstranhas'] ?? 'N/A'}</span></div>
        ${laudo.containsKey('queimados') ? '<div class="info-row"><span class="label">Queimados:</span> <span class="value">${laudo['queimados'] ?? 'N/A'}</span></div>' : ''}
        ${laudo.containsKey('ardidos') ? '<div class="info-row"><span class="label">Ardidos:</span> <span class="value">${laudo['ardidos'] ?? 'N/A'}</span></div>' : ''}
        ${laudo.containsKey('mofados') ? '<div class="info-row"><span class="label">Mofados:</span> <span class="value">${laudo['mofados'] ?? 'N/A'}</span></div>' : ''}
    </div>
    
    <div class="footer">
        <div>AGROCLASS MOBILE - Laudo de Clientes</div>
        <div>Gerado em: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year} às ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}</div>
    </div>
</body>
</html>
    ''';
    
    // Abrir em nova janela para impressão
    // Em web, vamos usar uma abordagem diferente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Text('HTML gerado! Use Ctrl+P para imprimir.'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 5),
      ),
    );
    
    // Para web, vamos redirecionar para uma página com o HTML
    // Esta é uma solução alternativa para Flutter Web
    if (kIsWeb) {
      // Em produção, isso abriria o HTML em uma nova aba
      // Por enquanto, mostramos apenas a mensagem
      print('HTML gerado para impressão: ${html.length} caracteres');
    }
  }


  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalhesLaudo(Map<String, dynamic> laudo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF1e293b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF63b14a).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Color(0xFF63b14a),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laudo ${laudo['id'] ?? 'N/A'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            laudo['servico'] ?? 'N/A',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Conteúdo do laudo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Data:', laudo['data'] ?? 'N/A'),
                      _buildDetailRow('Status:', _getStatusText(laudo)),
                      if (laudo['cliente'] != null) _buildDetailRow('Cliente:', laudo['cliente']),
                      if (laudo['origem'] != null) _buildDetailRow('Origem:', laudo['origem']),
                      if (laudo['destino'] != null) _buildDetailRow('Destino:', laudo['destino']),
                      if (laudo['produto'] != null) _buildDetailRow('Produto:', laudo['produto']),
                      if (laudo['placa'] != null) _buildDetailRow('Placa:', laudo['placa']),
                      if (laudo['notaFiscal'] != null) _buildDetailRow('Nota Fiscal:', laudo['notaFiscal']),
                      if (laudo['certificadora'] != null) _buildDetailRow('Certificadora:', laudo['certificadora']),
                      if (laudo['odor'] != null) _buildDetailRow('Odor:', laudo['odor']),
                      if (laudo['sementes'] != null) _buildDetailRow('Sementes:', laudo['sementes']),
                      if (laudo['tipo'] != null) _buildDetailRow('Tipo Divergência:', laudo['tipo']),
                      if (laudo['terminalRecusa'] != null) _buildDetailRow('Terminal Recusa:', laudo['terminalRecusa']),
                      if (laudo['resultado'] != null) _buildDetailRow('Resultado:', laudo['resultado']),
                      if (laudo['observacoes'] != null && laudo['observacoes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Observações:',
                          style: TextStyle(
                            color: Color(0xFF63b14a),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          laudo['observacoes'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Gerar PDF
                          PdfService.gerarPdfLaudo(laudo);
                        },
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text('Gerar PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF63b14a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF63b14a)),
                          foregroundColor: const Color(0xFF63b14a),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF63b14a),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0f172a),
                Color(0xFF1e293b),
                Color(0xFF334155),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
              
              // Filtros Responsivos - Cabem na tela
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Filtro Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: DropdownButton<String>(
                        value: _filtroStatus,
                        dropdownColor: const Color(0xFF1e293b),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        underline: const SizedBox(),
                        isDense: true,
                        iconSize: 16,
                        items: const [
                          DropdownMenuItem(value: 'todos', child: Text('St', style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'concluidos', child: Text('Ok', style: TextStyle(fontSize: 11))),
                          DropdownMenuItem(value: 'em_andamento', child: Text('And', style: TextStyle(fontSize: 11))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filtroStatus = value ?? 'todos';
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                    
                    // Filtro Clientes
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: DropdownButton<String>(
                        value: _filtroAuditor,
                        dropdownColor: const Color(0xFF1e293b),
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        underline: const SizedBox(),
                        isDense: true,
                        iconSize: 16,
                        items: _getClientesOptionsCompact(),
                        onChanged: (value) {
                          setState(() {
                            _filtroAuditor = value ?? 'todos';
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                    
                    // Filtro Data Início
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _filtroDataInicio ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _filtroDataInicio = date;
                            _aplicarFiltros();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1e293b),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF63b14a)),
                            const SizedBox(width: 2),
                            Text(
                              _filtroDataInicio != null 
                                  ? '${_filtroDataInicio!.day}/${_filtroDataInicio!.month}'
                                  : 'Início',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Filtro Data Fim
                    GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _filtroDataFim ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            _filtroDataFim = date;
                            _aplicarFiltros();
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1e293b),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Color(0xFF63b14a)),
                            const SizedBox(width: 2),
                            Text(
                              _filtroDataFim != null 
                                  ? '${_filtroDataFim!.day}/${_filtroDataFim!.month}'
                                  : 'Fim',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botão Limpar
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _filtroStatus = 'todos';
                          _filtroAuditor = 'todos';
                          _filtroDataInicio = null;
                          _filtroDataFim = null;
                          _aplicarFiltros();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFef4444),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear, size: 12, color: Colors.white),
                            SizedBox(width: 2),
                            Text('Limpar', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _laudosFiltrados.length,
                  itemBuilder: (context, index) {
                    final laudo = _laudosFiltrados[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header do card com barra de sincronização integrada
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF63b14a).withOpacity(0.1),
                                  const Color(0xFF63b14a).withOpacity(0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: (laudo['sincronizado'] == true) 
                                      ? Colors.green
                                      : Colors.orange,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // ID (sem ícone)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Laudo ${laudo['id'] ?? 'N/A'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        laudo['servico'] ?? 'N/A',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(laudo).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _getStatusColor(laudo).withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getStatusIcon(laudo),
                                        size: 12,
                                        color: _getStatusColor(laudo),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _getStatusText(laudo),
                                        style: TextStyle(
                                          color: _getStatusColor(laudo),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Conteúdo principal
                          Container(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Column(
                              children: [
                                // Data e informações básicas
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.6)),
                                    const SizedBox(width: 4),
                                    Text(
                                      laudo['data'] ?? 'N/A',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    if (laudo['cliente'] != null) ...[
                                      Icon(Icons.person, size: 14, color: Colors.white.withOpacity(0.6)),
                                      const SizedBox(width: 4),
                                      Text(
                                        laudo['cliente'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                const SizedBox(height: 4),
                                
                                // Informações do produto
                                if (laudo['produto'] != null || laudo['placa'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        if (laudo['produto'] != null) ...[
                                          Icon(Icons.inventory_2, size: 14, color: const Color(0xFF63b14a)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              laudo['produto'],
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (laudo['produto'] != null && laudo['placa'] != null)
                                          const SizedBox(width: 12),
                                        if (laudo['placa'] != null) ...[
                                          Icon(Icons.local_shipping, size: 14, color: const Color(0xFF63b14a)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              laudo['placa'],
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 4),
                                
                                // Ação - Apenas PDF
                                SizedBox(
                                  width: double.infinity,
                                  child: _buildActionButton(
                                    'Gerar PDF',
                                    Icons.picture_as_pdf,
                                    const Color(0xFFe74c3c),
                                    () async {
                                      try {
                                        await PdfService.gerarPdfLaudo(laudo);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.check, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text('PDF gerado com sucesso!'),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.error, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text('Erro ao gerar PDF. Tente novamente.'),
                                              ],
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),  
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Método para determinar o status baseado no campo resultado
  String _getStatusText(Map<String, dynamic> laudo) {
    if (laudo['resultado'] == null || laudo['resultado'].toString().trim().isEmpty) {
      return 'Em Andamento';
    } else {
      return 'Concluída';
    }
  }

  // Método para obter a cor do status
  Color _getStatusColor(Map<String, dynamic> laudo) {
    if (laudo['resultado'] == null || laudo['resultado'].toString().trim().isEmpty) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Método para obter o ícone do status
  IconData _getStatusIcon(Map<String, dynamic> laudo) {
    if (laudo['resultado'] == null || laudo['resultado'].toString().trim().isEmpty) {
      return Icons.pending;
    } else {
      return Icons.check_circle;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auditorias',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Todas as auditorias: ${_laudos.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFcbd5e1),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF63b14a).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.assessment,
              color: Color(0xFF63b14a),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
