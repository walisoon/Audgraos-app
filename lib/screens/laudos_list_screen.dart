import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'classificacao_laudo_screen.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';

// Timestamp para forçar reload
final String _buildVersion = 'v2.1-${DateTime.now().millisecondsSinceEpoch}';

class LaudosListScreen extends StatefulWidget {
  const LaudosListScreen({super.key});

  // Instância estática para acesso global
  static _LaudosListScreenState? _instance;

  static void adicionarLaudo(Map<String, dynamic> laudo) {
    _instance?._adicionarLaudo(laudo);
  }

  static void atualizarLista() {
    _instance?._carregarLaudosSalvos();
  }

  @override
  State<LaudosListScreen> createState() {
    final state = _LaudosListScreenState();
    _instance = state;
    return state;
  }
}

class _LaudosListScreenState extends State<LaudosListScreen> {
  List<Map<String, dynamic>> _laudos = <Map<String, dynamic>>[];
  bool _carregando = false;

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
      debugPrint('=== CARREGANDO LAUDOS SALVOS ===');
      final laudos = await StorageService.carregarLaudos();
      debugPrint('Laudos carregados: ${laudos.length}');
      setState(() {
        _laudos = laudos;
        _carregando = false;
      });
      debugPrint('Estado atualizado com ${_laudos.length} laudos');
    } catch (e) {
      debugPrint('Erro ao carregar laudos: $e');
      setState(() {
        _carregando = false;
      });
    }
  }

  void _adicionarLaudo(Map<String, dynamic> laudo) {
    setState(() {
      _laudos.add(laudo);
    });
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
        // Remover da lista
        setState(() {
          _laudos.removeWhere((l) => l['id'] == laudo['id']);
        });
        
        // Remover do storage
        await StorageService.excluirLaudo(laudo['id']);
        
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(0, 48),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
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
                      _buildDetailRow('Status:', laudo['status'] ?? 'N/A'),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        toolbarHeight: 90,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Laudos de Clientes $_buildVersion',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF061126), Color(0xFF0a1b30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF061126), Color(0xFF0e1a2f), Color(0xFF0f172a)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1e293b),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total de Laudos',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_laudos.length}',
                              style: const TextStyle(
                                color: Color(0xFF63b14a),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1e293b),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Concluídos',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_laudos.where((l) => l['status'] == 'Concluído').length}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _novoLaudo,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Novo Laudo',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF63b14a),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _laudos.length,
                  itemBuilder: (context, index) {
                    final laudo = _laudos[index];
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
                          // Header do card
                          Container(
                            padding: const EdgeInsets.all(20),
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
                            ),
                            child: Row(
                              children: [
                                // Icon e ID
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF63b14a).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.description,
                                    color: Color(0xFF63b14a),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
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
                                      const SizedBox(height: 4),
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
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: laudo['status'] == 'Concluído' 
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: laudo['status'] == 'Concluído' 
                                          ? Colors.green.withOpacity(0.5)
                                          : Colors.orange.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        laudo['status'] == 'Concluído' 
                                            ? Icons.check_circle
                                            : Icons.pending,
                                        size: 14,
                                        color: laudo['status'] == 'Concluído' 
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        laudo['status'] ?? 'N/A',
                                        style: TextStyle(
                                          color: laudo['status'] == 'Concluído' 
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 12,
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
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Data e informações básicas
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.white.withOpacity(0.6)),
                                    const SizedBox(width: 6),
                                    Text(
                                      laudo['data'] ?? 'N/A',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    if (laudo['cliente'] != null) ...[
                                      Icon(Icons.person, size: 16, color: Colors.white.withOpacity(0.6)),
                                      const SizedBox(width: 6),
                                      Text(
                                        laudo['cliente'],
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Informações do produto
                                if (laudo['produto'] != null || laudo['placa'] != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        if (laudo['produto'] != null) ...[
                                          Icon(Icons.inventory_2, size: 16, color: const Color(0xFF63b14a)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              laudo['produto'],
                                              style: const TextStyle(
                                                color: Color(0xFF63b14a),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (laudo['placa'] != null) ...[
                                          Icon(Icons.local_shipping, size: 16, color: const Color(0xFF63b14a)),
                                          const SizedBox(width: 8),
                                          Text(
                                            laudo['placa'],
                                            style: const TextStyle(
                                              color: Color(0xFF63b14a),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                
                                const SizedBox(height: 16),
                                
                                // Resultados
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInfoCard(
                                        'Terminal Recusa',
                                        laudo['terminalRecusa'] ?? 'N/A',
                                        Icons.location_off,
                                        Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildInfoCard(
                                        'Resultado Auditoria',
                                        laudo['resultado'] ?? 'N/A',
                                        Icons.assessment,
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Botões de ação
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildActionButton(
                                    'Editar',
                                    Icons.edit,
                                    Colors.blue,
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ClassificacaoLaudoScreen(
                                          ordemNumero: laudo['id'],
                                          servico: laudo['servico'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    'Imprimir',
                                    Icons.print,
                                    const Color(0xFF63b14a),
                                    () async {
                                      try {
                                        await PdfService.gerarPdfLaudo(laudo);
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    'Visualizar',
                                    Icons.visibility,
                                    Colors.purple,
                                    () => _mostrarDetalhesLaudo(laudo),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    'Compartilhar',
                                    Icons.share,
                                    Colors.orange,
                                    () async {
                                      try {
                                        await PdfService.salvarECompartilharPdf(laudo);
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.error, color: Colors.white),
                                                SizedBox(width: 8),
                                                Text('Erro ao compartilhar PDF. Tente novamente.'),
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
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildActionButton(
                                    'Excluir',
                                    Icons.delete,
                                    Colors.red,
                                    () => _excluirLaudo(laudo),
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
    );
  }
}
