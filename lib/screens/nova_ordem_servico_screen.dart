import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class NovaOrdemServicoScreen extends StatefulWidget {
  const NovaOrdemServicoScreen({super.key});

  @override
  State<NovaOrdemServicoScreen> createState() => _NovaOrdemServicoScreenState();
}

class _NovaOrdemServicoScreenState extends State<NovaOrdemServicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _loteController = TextEditingController();
  final _embarqueController = TextEditingController();
  final _destinoController = TextEditingController();
  final _servicoController = TextEditingController();

  String? _clienteSelecionado;
  String _prioridade = 'media';
  String _status = 'pendente';
  DateTime _dataSelecionada = DateTime.now();
  
  // Lista de clientes do storage
  List<Map<String, dynamic>> _clientes = [];
  bool _carregandoClientes = false;

  final List<String> _servicos = [
    'Auditoria de Soja',
    'Auditoria de Milho',
    'Auditoria de Trigo',
    'Análise de Solo',
    'Auditoria de Café',
    'Auditoria de Qualidade',
  ];

  @override
  void initState() {
    super.initState();
    _numeroController.text = 'OS-${DateTime.now().millisecondsSinceEpoch}';
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    setState(() {
      _carregandoClientes = true;
    });
    
    try {
      final clientes = await StorageService.carregarClientes();
      setState(() {
        _clientes = clientes;
        _carregandoClientes = false;
      });
    } catch (e) {
      setState(() {
        _clientes = [];
        _carregandoClientes = false;
      });
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _loteController.dispose();
    _embarqueController.dispose();
    _destinoController.dispose();
    _servicoController.dispose();
    super.dispose();
  }

  void _salvarOrdemServico() async {
    if (_formKey.currentState!.validate()) {
      final ordemServico = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'numero': _numeroController.text,
        'cliente': _clienteSelecionado ?? '',
        'servico': _servicoController.text,
        'status': _status,
        'data': _dataSelecionada.toIso8601String(),
        'prioridade': _prioridade,
        'valor': 0.0, // Valor padrão
        'embarque': _embarqueController.text,
        'destino': _destinoController.text,
        'produto': _servicoController.text,
        'lote': _loteController.text,
        'saldo': 0.0, // Saldo padrão
      };

      try {
        // Salvar ordem no storage
        await StorageService.adicionarOrdemServico(ordemServico);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordem de serviço criada com sucesso!'),
            backgroundColor: Color(0xFF63b14a),
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pop(context, ordemServico);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar ordem de serviço'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarSelecaoCliente() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Selecionar Cliente',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            if (_carregandoClientes)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF63b14a)),
                ),
              )
            else if (_clientes.isEmpty)
              Column(
                children: [
                  Icon(
                    Icons.person_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum cliente cadastrado',
                    style: TextStyle(
                      color: Color(0xFFcbd5e1),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Cadastre clientes primeiro na tela de Clientes',
                    style: TextStyle(
                      color: Color(0xFF64748b),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              ..._clientes.map((cliente) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF63b14a).withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    color: const Color(0xFF63b14a),
                  ),
                ),
                title: Text(
                  cliente['nome'] ?? 'Cliente sem nome',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  cliente['documento'] ?? 'Sem documento',
                  style: const TextStyle(
                    color: Color(0xFFcbd5e1),
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _clienteSelecionado = cliente['nome'];
                  });
                  Navigator.pop(context);
                },
              )),
            const SizedBox(height: 20),
          ],
        ),
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
        title: const Text(
          'Nova Ordem de Serviço',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF63b14a),
                Color(0xFF4a8f3a),
              ],
            ),
          ),
        ),
      ),
      body: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Número da Ordem
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextFormField(
                    controller: _numeroController,
                    enabled: false,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Número da Ordem',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.assignment,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Cliente
                GestureDetector(
                  onTap: _mostrarSelecaoCliente,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: const Color(0xFF63b14a),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _clienteSelecionado ?? 'Selecione um cliente',
                              style: TextStyle(
                                color: _clienteSelecionado != null 
                                  ? Colors.white 
                                  : const Color(0xFFcbd5e1),
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: const Color(0xFFcbd5e1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Data
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Data',
                      labelStyle: const TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      prefixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    initialValue:
                        '${_dataSelecionada.day.toString().padLeft(2, '0')}/${_dataSelecionada.month.toString().padLeft(2, '0')}/${_dataSelecionada.year}',
                    onTap: () async {
                      final data = await showDatePicker(
                        context: context,
                        initialDate: _dataSelecionada,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (data != null) {
                        setState(() {
                          _dataSelecionada = data;
                        });
                      }
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Serviço
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _servicoController.text.isNotEmpty ? _servicoController.text : null,
                    decoration: const InputDecoration(
                      labelText: 'Serviço',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.work,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1e293b),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    items: _servicos.map((servico) {
                      return DropdownMenuItem(
                        value: servico,
                        child: Text(servico),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _servicoController.text = value ?? '';
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Lote
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextFormField(
                    controller: _loteController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Lote',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.inventory,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o lote';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Embarque
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextFormField(
                    controller: _embarqueController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Local de Embarque',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.location_on,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o local de embarque';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Destino
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: TextFormField(
                    controller: _destinoController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.flag,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o destino';
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Prioridade
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _prioridade,
                    decoration: const InputDecoration(
                      labelText: 'Prioridade',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.priority_high,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1e293b),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
                      DropdownMenuItem(value: 'media', child: Text('Média')),
                      DropdownMenuItem(value: 'alta', child: Text('Alta')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _prioridade = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Status
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(
                        color: Color(0xFFcbd5e1),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(20),
                      prefixIcon: Icon(
                        Icons.info,
                        color: Color(0xFF63b14a),
                      ),
                    ),
                    dropdownColor: const Color(0xFF1e293b),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                      DropdownMenuItem(value: 'em_andamento', child: Text('Em Andamento')),
                      DropdownMenuItem(value: 'concluida', child: Text('Concluída')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value!;
                      });
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Botão Salvar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _salvarOrdemServico,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF63b14a),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 12),
                        Text(
                          'Salvar Ordem de Serviço',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
