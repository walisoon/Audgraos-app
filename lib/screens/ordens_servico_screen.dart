import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'classificacao_laudo_screen.dart';
import 'nova_ordem_servico_screen.dart';
import '../services/storage_service.dart';

class OrdemServico {
  final String id;
  final String numero;
  final String cliente;
  final String servico;
  final String status;
  final DateTime data;
  final String prioridade;
  final double valor;
  final String embarque;
  final String destino;
  final String produto;
  final String lote;
  final double saldo;

  OrdemServico({
    required this.id,
    required this.numero,
    required this.cliente,
    required this.servico,
    required this.status,
    required this.data,
    required this.prioridade,
    required this.valor,
    required this.embarque,
    required this.destino,
    required this.produto,
    required this.lote,
    required this.saldo,
  });
}

class OrdensServicoScreen extends StatefulWidget {
  const OrdensServicoScreen({super.key});

  @override
  State<OrdensServicoScreen> createState() => _OrdensServicoScreenState();
}

class _OrdensServicoScreenState extends State<OrdensServicoScreen> {
  String selectedFilter = 'todas';
  List<OrdemServico> ordens = [];

  @override
  void initState() {
    super.initState();
    _carregarOrdensServico();
  }

  Future<void> _carregarOrdensServico() async {
    try {
      final ordensSalvas = await StorageService.carregarOrdensServico();
      
      // Converter para OrdemServico objects
      final ordensConvertidas = ordensSalvas.map((ordemMap) {
        return OrdemServico(
          id: ordemMap['id'] ?? '',
          numero: ordemMap['numero'] ?? '',
          cliente: ordemMap['cliente'] ?? '',
          servico: ordemMap['servico'] ?? '',
          status: ordemMap['status'] ?? 'pendente',
          data: DateTime.tryParse(ordemMap['data']) ?? DateTime.now(),
          prioridade: ordemMap['prioridade'] ?? 'media',
          valor: (ordemMap['valor'] ?? 0.0).toDouble(),
          embarque: ordemMap['embarque'] ?? '',
          destino: ordemMap['destino'] ?? '',
          produto: ordemMap['produto'] ?? '',
          lote: ordemMap['lote'] ?? '',
          saldo: (ordemMap['saldo'] ?? 0.0).toDouble(),
        );
      }).toList();

      // Não adicionar ordens de exemplo - iniciar vazio
      setState(() {
        ordens = ordensConvertidas;
      });
    } catch (e) {
      print('Erro ao carregar ordens: $e');
    }
  }

  List<OrdemServico> get filteredOrdens {
    if (selectedFilter == 'todas') return ordens;
    return ordens.where((os) => os.status == selectedFilter).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'em_andamento':
        return Colors.blue;
      case 'concluida':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'em_andamento':
        return 'Em Andamento';
      case 'concluida':
        return 'Concluída';
      default:
        return status;
    }
  }

  Color getPriorityColor(String prioridade) {
    switch (prioridade) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'baixa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _abrirLaudoClassificacao(OrdemServico ordem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassificacaoLaudoScreen(
          ordemNumero: ordem.numero,
          servico: ordem.servico,
        ),
      ),
    );
  }

  void _novaOrdemServico() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NovaOrdemServicoScreen(),
      ),
    );

    if (result != null) {
      // Adicionar a nova ordem à lista e salvar no storage
      final novaOrdem = OrdemServico(
        id: result['id'],
        numero: result['numero'],
        cliente: result['cliente'],
        servico: result['servico'],
        status: result['status'],
        data: result['data'],
        prioridade: result['prioridade'],
        valor: result['valor'],
        embarque: result['embarque'],
        destino: result['destino'],
        produto: result['produto'],
        lote: result['lote'],
        saldo: result['saldo'],
      );

      setState(() {
        ordens.add(novaOrdem);
      });

      // Salvar no armazenamento local
      await StorageService.adicionarOrdemServico(result);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordem de serviço criada e salva com sucesso!'),
          backgroundColor: Color(0xFF63b14a),
          duration: Duration(seconds: 3),
        ),
      );
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
                _buildHeader(),
                // Filtros
                _buildFilters(),
                // Botão Nova Ordem de Serviço
                _buildNovaOrdemButton(),
                // Lista de Ordens
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrdens.length,
                    itemBuilder: (context, index) {
                      final ordem = filteredOrdens[index];
                      return _buildOrdemCard(ordem);
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
                  'Ordens de Serviço',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${ordens.length} ordens encontradas',
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
              Icons.assignment,
              color: Color(0xFF63b14a),
              size: 24,
            ),
          ),
        ],
      ),
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
            _buildFilterChip('pendente', 'Pendentes'),
            const SizedBox(width: 8),
            _buildFilterChip('em_andamento', 'Em Andamento'),
            const SizedBox(width: 8),
            _buildFilterChip('concluida', 'Concluídas'),
          ],
        ),
      ),
    );
  }

  Widget _buildNovaOrdemButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _novaOrdemServico,
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          label: const Text(
            'Nova Ordem de Serviço',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF63b14a),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF63b14a).withOpacity(0.3),
          ),
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
      selectedColor: const Color(0xFF63b14a).withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFFcbd5e1),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF63b14a) : const Color(0xFF475569),
      ),
    );
  }

  Widget _buildOrdemCard(OrdemServico ordem) {
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
          // TODO: Navegar para detalhes da OS
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Detalhes da OS ${ordem.numero}'),
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
                          ordem.numero,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ordem.cliente,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFcbd5e1),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                      color: getStatusColor(ordem.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      getStatusText(ordem.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: getStatusColor(ordem.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Embarque e Destino
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: const Color(0xFF64748b),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${ordem.embarque} → ${ordem.destino}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748b),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Produto e Lote
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF63b14a).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ordem.produto,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ordem.lote,
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
                      GestureDetector(
                        onTap: () => _abrirLaudoClassificacao(ordem),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 12,
                            color: Color(0xFFcbd5e1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.list_alt,
                          size: 12,
                          color: Color(0xFFcbd5e1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.warning,
                          size: 12,
                          color: Color(0xFFcbd5e1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Serviço
              Row(
                children: [
                  Icon(
                    Icons.agriculture,
                    size: 16,
                    color: const Color(0xFF63b14a),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ordem.servico,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFe2e8f0),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Data e prioridade
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: const Color(0xFF64748b),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ordem.data.day.toString().padLeft(2, '0')}/${ordem.data.month.toString().padLeft(2, '0')}/${ordem.data.year}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: getPriorityColor(ordem.prioridade),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Prioridade ${ordem.prioridade}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748b),
                    ),
                  ),
                  const SizedBox(width: 26),
                  Text(
                    'Saldo: ${ordem.saldo.toStringAsFixed(0)} Ton',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF63b14a),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
