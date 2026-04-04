import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class Auditoria {
  final String id;
  final String codigo;
  final String titulo;
  final String tipo;
  final String status;
  final DateTime data;
  final String auditor;
  final String area;
  final double pontuacao;
  final int naoConformidades;

  Auditoria({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.tipo,
    required this.status,
    required this.data,
    required this.auditor,
    required this.area,
    required this.pontuacao,
    required this.naoConformidades,
  });
}

class AuditoriasScreen extends StatefulWidget {
  const AuditoriasScreen({super.key});

  // Instância estática para acesso global
  static _AuditoriasScreenState? _instance;

  static void adicionarLaudo(Map<String, dynamic> laudo) {
    _instance?._adicionarLaudo(laudo);
  }

  @override
  State<AuditoriasScreen> createState() {
    final state = _AuditoriasScreenState();
    _instance = state;
    return state;
  }
}

class _AuditoriasScreenState extends State<AuditoriasScreen> {
  String selectedFilter = 'todas';
  String selectedTab = 'auditorias'; // 'auditorias' ou 'laudos'
  
  final List<Auditoria> auditorias = [
    Auditoria(
      id: '1',
      codigo: 'AUD-2024-001',
      titulo: 'Auditoria de Processos de Auditoria',
      tipo: 'interna',
      status: 'agendada',
      data: DateTime.now().add(const Duration(days: 2)),
      auditor: 'João Silva',
      area: 'Produção',
      pontuacao: 0.0,
      naoConformidades: 0,
    ),
    Auditoria(
      id: '2',
      codigo: 'AUD-2024-002',
      titulo: 'Verificação de Normas de Segurança',
      tipo: 'seguranca',
      status: 'em_andamento',
      data: DateTime.now().subtract(const Duration(days: 1)),
      auditor: 'Maria Santos',
      area: 'Segurança',
      pontuacao: 85.5,
      naoConformidades: 2,
    ),
    Auditoria(
      id: '3',
      codigo: 'AUD-2024-003',
      titulo: 'Auditoria de Qualidade de Insumos',
      tipo: 'qualidade',
      status: 'concluida',
      data: DateTime.now().subtract(const Duration(days: 5)),
      auditor: 'Carlos Oliveira',
      area: 'Qualidade',
      pontuacao: 92.3,
      naoConformidades: 1,
    ),
    Auditoria(
      id: '4',
      codigo: 'AUD-2024-004',
      titulo: 'Auditoria Ambiental',
      tipo: 'ambiental',
      status: 'concluida',
      data: DateTime.now().subtract(const Duration(days: 10)),
      auditor: 'Ana Costa',
      area: 'Meio Ambiente',
      pontuacao: 78.9,
      naoConformidades: 3,
    ),
  ];

  // Lista de laudos salvos
  List<Map<String, dynamic>> _laudosSalvos = [];

  @override
  void initState() {
    super.initState();
    _carregarLaudos();
  }

  Future<void> _carregarLaudos() async {
    try {
      final laudos = await StorageService.carregarLaudos();
      setState(() {
        _laudosSalvos = laudos;
      });
    } catch (e) {
      print('Erro ao carregar laudos: $e');
    }
  }

  List<Auditoria> get filteredAuditorias {
    if (selectedFilter == 'todas') return auditorias;
    return auditorias.where((aud) => aud.status == selectedFilter).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'agendada':
        return Colors.blue;
      case 'em_andamento':
        return Colors.orange;
      case 'concluida':
        return Colors.green;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'agendada':
        return 'Agendada';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  Color getTipoColor(String tipo) {
    switch (tipo) {
      case 'interna':
        return Colors.purple;
      case 'seguranca':
        return Colors.red;
      case 'qualidade':
        return Colors.green;
      case 'ambiental':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String getTipoText(String tipo) {
    switch (tipo) {
      case 'interna':
        return 'Interna';
      case 'seguranca':
        return 'Segurança';
      case 'qualidade':
        return 'Qualidade';
      case 'ambiental':
        return 'Ambiental';
      default:
        return tipo;
    }
  }

  Color getPontuacaoColor(double pontuacao) {
    if (pontuacao >= 90) return Colors.green;
    if (pontuacao >= 70) return Colors.orange;
    return Colors.red;
  }

  void _adicionarLaudo(Map<String, dynamic> laudo) async {
    // Salvar no armazenamento local
    await StorageService.adicionarLaudo(laudo);
    
    // Recarregar laudos do storage
    await _carregarLaudos();
    
    // Mudar para a aba de laudos automaticamente
    setState(() {
      selectedTab = 'laudos';
    });
  }

  void _abrirDetalhesLaudo(Map<String, dynamic> laudo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: Row(
          children: [
            Text(
              'Laudo - ${laudo['id']}',
              style: const TextStyle(color: Colors.white),
            ),
            const Spacer(),
            // Botão PDF no diálogo
            IconButton(
              onPressed: () async {
                try {
                  await StorageService.gerarPdfLaudo(laudo);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PDF gerado com sucesso!'),
                      backgroundColor: Color(0xFF63b14a),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao gerar PDF'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF63b14a),
              ),
              tooltip: 'Gerar PDF',
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Serviço:', laudo['servico']),
              _buildDetailRow('Data:', laudo['data']),
              _buildDetailRow('Status:', laudo['status']),
              if (laudo.containsKey('origem')) _buildDetailRow('Origem:', laudo['origem']),
              if (laudo.containsKey('destino')) _buildDetailRow('Destino:', laudo['destino']),
              if (laudo.containsKey('notaFiscal')) _buildDetailRow('Nota Fiscal:', laudo['notaFiscal']),
              if (laudo.containsKey('produto')) _buildDetailRow('Produto:', laudo['produto']),
              if (laudo.containsKey('cliente')) _buildDetailRow('Cliente:', laudo['cliente']),
              if (laudo.containsKey('placa')) _buildDetailRow('Placa:', laudo['placa']),
              if (laudo.containsKey('umidade')) _buildDetailRow('Umidade:', laudo['umidade']),
              if (laudo.containsKey('materiasEstranhas')) _buildDetailRow('Mat. Estranhas:', laudo['materiasEstranhas']),
              if (laudo.containsKey('odor')) _buildDetailRow('Odor:', laudo['odor']),
              if (laudo.containsKey('sementes')) _buildDetailRow('Sementes:', laudo['sementes']),
              if (laudo.containsKey('observacoes')) ...[
                const SizedBox(height: 8),
                const Text(
                  'Observações:',
                  style: TextStyle(
                    color: Color(0xFF63b14a),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  laudo['observacoes'],
                  style: const TextStyle(color: Color(0xFFcbd5e1)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: Color(0xFF63b14a))),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF63b14a),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(color: Color(0xFFcbd5e1)),
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
                // Abas
                _buildTabs(),
                // Conteúdo baseado na aba selecionada
                Expanded(
                  child: _buildAuditoriasContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                  '${auditorias.length} auditorias encontradas',
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
              color: const Color(0xFF3b82f6).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              selectedTab == 'auditorias' ? Icons.fact_check : Icons.description,
              color: const Color(0xFF3b82f6),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedTab = 'auditorias'),
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
                  'Auditorias',
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
    );
  }

  Widget _buildAuditoriasContent() {
    return Column(
      children: [
        // Filtros
        _buildFilters(),
        // Lista de Auditorias
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAuditorias.length,
            itemBuilder: (context, index) {
              final auditoria = filteredAuditorias[index];
              return _buildAuditoriaCard(auditoria);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLaudosContent() {
    if (_laudosSalvos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum laudo salvo',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Os laudos gerados aparecerão aqui',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _laudosSalvos.length,
      itemBuilder: (context, index) {
        final laudo = _laudosSalvos[index];
        return _buildLaudoCard(laudo);
      },
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('todas', 'Todas'),
            const SizedBox(width: 8),
            _buildFilterChip('agendada', 'Agendadas'),
            const SizedBox(width: 8),
            _buildFilterChip('em_andamento', 'Em Andamento'),
            const SizedBox(width: 8),
            _buildFilterChip('concluida', 'Concluídas'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      backgroundColor: const Color(0xFF1e293b),
      selectedColor: const Color(0xFF3b82f6).withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFFcbd5e1),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3b82f6) : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildAuditoriaCard(Auditoria auditoria) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155).withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar para detalhes da auditoria
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detalhes da auditoria ${auditoria.codigo}'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho do card
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auditoria.codigo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auditoria.titulo,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFcbd5e1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(auditoria.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getStatusText(auditoria.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(auditoria.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tipo e Área
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getTipoColor(auditoria.tipo).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getTipoText(auditoria.tipo),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: getTipoColor(auditoria.tipo),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: const Color(0xFF64748b),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    auditoria.area,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Auditor e Data
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: const Color(0xFF64748b),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    auditoria.auditor,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF64748b),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${auditoria.data.day.toString().padLeft(2, '0')}/${auditoria.data.month.toString().padLeft(2, '0')}/${auditoria.data.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748b),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Métricas
              if (auditoria.status == 'concluida') ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Pontuação',
                        '${auditoria.pontuacao.toStringAsFixed(1)}%',
                        getPontuacaoColor(auditoria.pontuacao),
                        Icons.assessment,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Não Conformidades',
                        auditoria.naoConformidades.toString(),
                        auditoria.naoConformidades > 2 ? Colors.red : Colors.orange,
                        Icons.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaudoCard(Map<String, dynamic> laudo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF63b14a).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do card
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laudo['id'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        laudo['servico'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFcbd5e1),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF63b14a).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    laudo['status'] ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF63b14a),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Data e informações
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: const Color(0xFF64748b),
                ),
                const SizedBox(width: 8),
                Text(
                  laudo['data'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748b),
                  ),
                ),
                const Spacer(),
                // Botões de ação
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão PDF
                    IconButton(
                      onPressed: () async {
                        try {
                          await StorageService.gerarPdfLaudo(laudo);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF gerado com sucesso!'),
                              backgroundColor: Color(0xFF63b14a),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erro ao gerar PDF'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Color(0xFF63b14a),
                        size: 20,
                      ),
                      tooltip: 'Gerar PDF',
                    ),
                    const SizedBox(width: 8),
                    // Botão detalhes
                    IconButton(
                      onPressed: () => _abrirDetalhesLaudo(laudo),
                      icon: Icon(
                        Icons.visibility,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      tooltip: 'Ver detalhes',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
