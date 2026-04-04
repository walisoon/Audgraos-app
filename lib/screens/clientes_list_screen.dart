import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class ClientesListScreen extends StatefulWidget {
  const ClientesListScreen({super.key});

  @override
  State<ClientesListScreen> createState() => _ClientesListScreenState();
}

class _ClientesListScreenState extends State<ClientesListScreen> {
  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    try {
      final clientes = await StorageService.carregarClientes();
      setState(() {
        _clientes = clientes;
      });
    } catch (e) {
      print('Erro ao carregar clientes: $e');
    }
  }

  void _novoCliente() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClienteFormScreen(),
      ),
    );

    if (result != null) {
      // Recarregar a lista de clientes
      await _carregarClientes();
    }
  }

  void _editarCliente(Map<String, dynamic> cliente) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteFormScreen(
          cliente: cliente,
        ),
      ),
    );

    if (result != null) {
      // Recarregar a lista de clientes
      await _carregarClientes();
    }
  }

  void _excluirCliente(int index) async {
    final cliente = _clientes[index];
    
    // Excluir do storage
    await StorageService.excluirCliente(cliente['id']);
    
    // Recarregar lista
    await _carregarClientes();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cliente excluído com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
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
        title: const Text(
          'Clientes',
          style: TextStyle(
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
                              'Total de Clientes',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_clientes.length}',
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
                              'Ativos',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_clientes.where((c) => c['status'] == 'Ativo').length}',
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
                    onPressed: _novoCliente,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Novo Cliente',
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
                child: _clientes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum cliente cadastrado',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Clique no botão "Novo Cliente" para começar',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _clientes.length,
                        itemBuilder: (context, index) {
                          final cliente = _clientes[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1e293b),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                cliente['nome'] ?? 'Nome não informado',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  if (cliente['documento'] != null)
                                    Text(
                                      'Documento: ${cliente['documento']}',
                                      style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 14),
                                    ),
                                  if (cliente['telefone'] != null)
                                    Text(
                                      'Telefone: ${cliente['telefone']}',
                                      style: const TextStyle(color: Color(0xFFcbd5e1), fontSize: 14),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.circle, size: 8, color: cliente['status'] == 'Ativo' ? Colors.green : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        cliente['status'] ?? 'Inativo',
                                        style: TextStyle(
                                          color: cliente['status'] == 'Ativo' ? Colors.green : Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, color: Colors.white70),
                                color: const Color(0xFF1e293b),
                                onSelected: (value) {
                                  if (value == 'editar') {
                                    _editarCliente(cliente);
                                  } else if (value == 'excluir') {
                                    _excluirCliente(index);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Color(0xFF63b14a), size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'excluir',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text('Excluir', style: TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

class ClienteFormScreen extends StatefulWidget {
  final Map<String, dynamic>? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  String _status = 'Ativo';

  // Funções de máscara
  String _applyPhoneMask(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length <= 11) {
      // Celular: (XX) XXXXX-XXXX
      if (value.length <= 2) return value;
      if (value.length <= 7) return '(${value.substring(0, 2)}) ${value.substring(2)}';
      return '(${value.substring(0, 2)}) ${value.substring(2, 7)}-${value.substring(7, 11)}';
    } else {
      // Telefone fixo: (XX) XXXX-XXXX
      if (value.length <= 2) return value;
      if (value.length <= 6) return '(${value.substring(0, 2)}) ${value.substring(2)}';
      if (value.length <= 10) return '(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6)}';
      return '(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6, 10)}';
    }
  }

  String _applyCpfMask(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length <= 3) return value;
    if (value.length <= 6) return '${value.substring(0, 3)}.${value.substring(3)}';
    if (value.length <= 9) return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6)}';
    return '${value.substring(0, 3)}.${value.substring(3, 6)}.${value.substring(6, 9)}-${value.substring(9, 11)}';
  }

  String _applyCnpjMask(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.length <= 2) return value;
    if (value.length <= 5) return '${value.substring(0, 2)}.${value.substring(2)}';
    if (value.length <= 8) return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5)}';
    if (value.length <= 12) return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5, 8)}/${value.substring(8)}';
    return '${value.substring(0, 2)}.${value.substring(2, 5)}.${value.substring(5, 8)}/${value.substring(8, 12)}-${value.substring(12, 14)}';
  }

  void _onPhoneChanged(String value) {
    final maskedValue = _applyPhoneMask(value);
    _telefoneController.value = TextEditingValue(
      text: maskedValue,
      selection: TextSelection.collapsed(offset: maskedValue.length),
    );
  }

  void _onDocumentChanged(String value) {
    String maskedValue;
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanValue.length <= 11) {
      maskedValue = _applyCpfMask(value);
    } else {
      maskedValue = _applyCnpjMask(value);
    }
    
    _documentoController.value = TextEditingValue(
      text: maskedValue,
      selection: TextSelection.collapsed(offset: maskedValue.length),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _nomeController.text = widget.cliente!['nome'] ?? '';
      _documentoController.text = widget.cliente!['documento'] ?? '';
      _telefoneController.text = widget.cliente!['telefone'] ?? '';
      _emailController.text = widget.cliente!['email'] ?? '';
      _enderecoController.text = widget.cliente!['endereco'] ?? '';
      _cidadeController.text = widget.cliente!['cidade'] ?? '';
      _estadoController.text = widget.cliente!['estado'] ?? '';
      _status = widget.cliente!['status'] ?? 'Ativo';
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }

  void _salvarCliente() async {
    if (_formKey.currentState!.validate()) {
      final cliente = {
        'id': widget.cliente?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'nome': _nomeController.text,
        'documento': _documentoController.text,
        'telefone': _telefoneController.text,
        'email': _emailController.text,
        'endereco': _enderecoController.text,
        'cidade': _cidadeController.text,
        'estado': _estadoController.text,
        'status': _status,
        'dataCadastro': widget.cliente?['dataCadastro'] ?? DateTime.now().toIso8601String(),
      };

      try {
        if (widget.cliente == null) {
          // Adicionar novo cliente
          await StorageService.adicionarCliente(cliente);
        } else {
          // Atualizar cliente existente
          await StorageService.atualizarCliente(widget.cliente!['id'], cliente);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cliente == null ? 'Cliente cadastrado com sucesso!' : 'Cliente atualizado com sucesso!'),
            backgroundColor: const Color(0xFF63b14a),
          ),
        );

        Navigator.pop(context, cliente);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar cliente'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente',
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e293b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nomeController,
                              decoration: const InputDecoration(
                                labelText: 'Nome do Cliente',
                                labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                prefixIcon: Icon(Icons.person, color: Color(0xFF63b14a)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe o nome do cliente';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _documentoController,
                              decoration: const InputDecoration(
                                labelText: 'Documento (CPF/CNPJ)',
                                labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                prefixIcon: Icon(Icons.document_scanner, color: Color(0xFF63b14a)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: _onDocumentChanged,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe o documento';
                                }
                                final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                                if (cleanValue.length == 11 || cleanValue.length == 14) {
                                  return null;
                                }
                                return 'CPF deve ter 11 dígitos ou CNPJ 14 dígitos';
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telefoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone',
                                labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                prefixIcon: Icon(Icons.phone, color: Color(0xFF63b14a)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: _onPhoneChanged,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                prefixIcon: Icon(Icons.email, color: Color(0xFF63b14a)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _enderecoController,
                              decoration: const InputDecoration(
                                labelText: 'Endereço',
                                labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                prefixIcon: Icon(Icons.location_on, color: Color(0xFF63b14a)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cidadeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Cidade',
                                      labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                      prefixIcon: Icon(Icons.location_city, color: Color(0xFF63b14a)),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF63b14a)),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF63b14a)),
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, informe a cidade';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _estadoController,
                                    decoration: const InputDecoration(
                                      labelText: 'UF',
                                      labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                      prefixIcon: Icon(Icons.map, color: Color(0xFF63b14a)),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF63b14a)),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF63b14a)),
                                      ),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    maxLength: 2,
                                    textCapitalization: TextCapitalization.characters,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'UF';
                                      }
                                      if (value.length != 2) {
                                        return '2 letras';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                labelStyle: TextStyle(color: Color(0xFFcbd5e1)),
                                prefixIcon: Icon(Icons.toggle_on, color: Color(0xFF63b14a)),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xFF63b14a)),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              dropdownColor: const Color(0xFF1e293b),
                              items: const [
                                DropdownMenuItem(value: 'Ativo', child: Text('Ativo', style: TextStyle(color: Colors.white))),
                                DropdownMenuItem(value: 'Inativo', child: Text('Inativo', style: TextStyle(color: Colors.white))),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _status = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _salvarCliente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF63b14a),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Salvar Cliente',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
