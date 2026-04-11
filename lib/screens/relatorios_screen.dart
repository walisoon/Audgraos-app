import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  List<Map<String, dynamic>> _relatorios = [];
  List<Map<String, dynamic>> _lancamentos = [];

  @override
  void initState() {
    super.initState();
    _carregarRelatorios();
    _carregarLancamentos();
  }

  Future<void> _carregarRelatorios() async {
    try {
      final relatorios = await StorageService.carregarRelatorios();
      setState(() {
        _relatorios = relatorios;
      });
    } catch (e) {
      print('Erro ao carregar relatórios: $e');
    }
  }

  Future<void> _carregarLancamentos() async {
    try {
      final lancamentos = await StorageService.carregarRelatorios();
      setState(() {
        _lancamentos = lancamentos;
      });
    } catch (e) {
      print('Erro ao carregar lançamentos: $e');
    }
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
                Container(
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
                              'Relatórios e Lançamentos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${_relatorios.length + _lancamentos.length} registros encontrados',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFcbd5e1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Abas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3b82f6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3b82f6),
                              ),
                            ),
                            child: Text(
                              'Relatórios',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF3b82f6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3b82f6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF3b82f6),
                              ),
                            ),
                            child: Text(
                              'Lançamentos',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF3b82f6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _relatorios.length + _lancamentos.length,
                    itemBuilder: (context, index) {
                      if (index < _relatorios.length) {
                        final relatorio = _relatorios[index];
                        return _buildRelatorioCard(relatorio);
                      } else {
                        final lancamento = _lancamentos[index - _relatorios.length];
                        return _buildLancamentoCard(lancamento);
                      }
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

  Widget _buildRelatorioCard(Map<String, dynamic> relatorio) {
    final isLaudo = relatorio['tipo'] == 'laudo_auditoria';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLaudo 
            ? const Color(0xFF63b14a).withOpacity(0.5)
            : const Color(0xFF334155).withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        relatorio['auditoria_titulo'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relatorio['auditoria_codigo'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcbd5e1),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isLaudo 
                      ? const Color(0xFF63b14a).withOpacity(0.2)
                      : const Color(0xFF3b82f6).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isLaudo ? 'LAUDO' : 'RELATÓRIO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isLaudo 
                        ? const Color(0xFF63b14a)
                        : const Color(0xFF3b82f6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Se for laudo, mostrar informações do laudo
            if (isLaudo) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF63b14a).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações do Laudo:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow('ID Laudo:', relatorio['laudo_id'] ?? 'N/A'),
                    _buildDetailRow('Serviço:', relatorio['laudo_servico'] ?? 'N/A'),
                    _buildDetailRow('Data Laudo:', relatorio['laudo_data'] ?? 'N/A'),
                    _buildDetailRow('Status Laudo:', relatorio['laudo_status'] ?? 'N/A'),
                  ],
                ),
              ),
            ],
            
            // Detalhes do relatório
            _buildDetailRow('Auditor:', relatorio['auditor'] ?? 'N/A'),
            _buildDetailRow('Data Geração:', relatorio['data_geracao'] ?? 'N/A'),
            _buildDetailRow('Tipo:', relatorio['tipo'] ?? 'N/A'),
            _buildDetailRow('Status:', relatorio['status'] ?? 'N/A'),
            if (!isLaudo) ...[
              _buildDetailRow('Pontuação:', '${relatorio['pontuacao'] ?? 'N/A'}%'),
              _buildDetailRow('Não Conformidades:', '${relatorio['nao_conformidades'] ?? 'N/A'}'),
            ],
            
            // Findings e Recomendações
            if (relatorio['findings'] != null && (relatorio['findings'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Findings:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              ...(relatorio['findings'] as List).map((finding) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $finding',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFcbd5e1),
                  ),
                ),
              )),
            ],
            
            if (relatorio['recomendacoes'] != null && (relatorio['recomendacoes'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recomendações:',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              ...(relatorio['recomendacoes'] as List).map((recomendacao) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '• $recomendacao',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFcbd5e1),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLancamentoCard(Map<String, dynamic> lancamento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF63b14a).withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lançamento',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lancamento['id'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcbd5e1),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF63b14a).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LANÇAMENTO',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF63b14a),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Detalhes
            _buildDetailRow('Descrição:', lancamento['descricao'] ?? 'N/A'),
            _buildDetailRow('Data:', lancamento['data_lancamento'] ?? 'N/A'),
            _buildDetailRow('Usuário:', lancamento['usuario'] ?? 'N/A'),
            _buildDetailRow('Auditoria:', lancamento['auditoria_codigo'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFcbd5e1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
