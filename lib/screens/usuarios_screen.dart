import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _nomeController = TextEditingController();
  List<Map<String, dynamic>> _usuarios = [];
  bool _isLoading = false;
  String _selectedTipo = 'auditor';

  @override
  void initState() {
    super.initState();
    _verificarPermissao();
    _carregarUsuarios();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  void _verificarPermissao() {
    if (!AuthService.podeAcessarUsuarios()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop(); // Volta para a tela anterior
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você não tem permissão para acessar esta função.'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  Future<void> _carregarUsuarios() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usuarios = await AuthService.carregarUsuarios();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar usuários: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _adicionarUsuario() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await AuthService.adicionarUsuario(
          _emailController.text.trim(),
          _senhaController.text,
          _nomeController.text.trim(),
          tipo: _selectedTipo,
        );

        // Limpar campos
        _emailController.clear();
        _senhaController.clear();
        _nomeController.clear();
        setState(() {
          _selectedTipo = 'auditor';
        });

        // Recarregar lista
        await _carregarUsuarios();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Usuário adicionado com sucesso!'),
              ],
            ),
            backgroundColor: Color(0xFF63b14a),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar usuário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _excluirUsuario(String email) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text('Confirmar Exclusão', style: TextStyle(color: Colors.white)),
        content: Text('Deseja realmente excluir o usuário $email?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF63b14a))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await AuthService.excluirUsuario(email);
        await _carregarUsuarios();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Usuário excluído com sucesso!'),
              ],
            ),
            backgroundColor: Color(0xFF63b14a),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir usuário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _editarUsuario(Map<String, dynamic> usuario) async {
    // Preencher formulário com dados do usuário
    _nomeController.text = usuario['nome'] ?? '';
    _emailController.text = usuario['email'] ?? '';
    _senhaController.text = ''; // Não preencher senha por segurança
    _selectedTipo = usuario['tipo'] ?? 'auditor';

    // Abrir diálogo de edição
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: Text('Editar Usuário: ${usuario['email']}', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Form(
            key: GlobalKey<FormState>(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField('Nome', _nomeController, Icons.person),
                _buildTextField('Email', _emailController, Icons.email),
                _buildTextField('Nova Senha (deixe em branco para manter atual)', _senhaController, Icons.lock, isPassword: true),
                _buildTipoDropdown(),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF63b14a))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar', style: TextStyle(color: Color(0xFF63b14a))),
          ),
        ],
      ),
    );

    if (resultado == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final usuarioAtualizado = {
          'email': _emailController.text.trim(),
          'nome': _nomeController.text.trim(),
          'tipo': _selectedTipo,
        };

        // Se senha foi preenchida, incluir na atualização
        if (_senhaController.text.isNotEmpty) {
          usuarioAtualizado['senha'] = _senhaController.text;
        }

        await AuthService.atualizarUsuario(usuario['email'], usuarioAtualizado);
        
        // Limpar campos
        _nomeController.clear();
        _emailController.clear();
        _senhaController.clear();
        _selectedTipo = 'auditor';

        // Recarregar lista
        await _carregarUsuarios();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Usuário atualizado com sucesso!'),
              ],
            ),
            backgroundColor: Color(0xFF63b14a),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar usuário: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text(
          'Gerenciar Usuários',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF63b14a)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulário de adição
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF63b14a).withOpacity(0.3)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Adicionar Novo Usuário',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField('Nome', _nomeController, Icons.person),
                          _buildTextField('Email', _emailController, Icons.email),
                          _buildTextField('Senha', _senhaController, Icons.lock, isPassword: true),
                          _buildTipoDropdown(),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _adicionarUsuario,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF63b14a),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Adicionar Usuário',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Lista de usuários
                  const Text(
                    'Usuários Cadastrados',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _usuarios.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum usuário cadastrado',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _usuarios.length,
                          itemBuilder: (context, index) {
                            final usuario = _usuarios[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1e293b),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      Row(
                                        children: [
                                          Text(
                                            usuario['nome'] ?? 'Sem nome',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: usuario['tipo'] == 'admin' 
                                                  ? Colors.red.withOpacity(0.8)
                                                  : Colors.blue.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              usuario['tipo'] == 'admin' ? 'Admin' : 'Auditor',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        usuario['email'] ?? 'Sem email',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _editarUsuario(usuario),
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                  ),
                                  IconButton(
                                    onPressed: () => _excluirUsuario(usuario['email']),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFFcbd5e1)),
          prefixIcon: Icon(icon, color: const Color(0xFF63b14a)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF63b14a)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF63b14a)),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, preencha $label';
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Email inválido';
          }
          if (label == 'Senha' && value.length < 6) {
            return 'Senha deve ter pelo menos 6 caracteres';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTipoDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedTipo,
        decoration: InputDecoration(
          labelText: 'Tipo de Usuário',
          labelStyle: const TextStyle(color: Color(0xFFcbd5e1)),
          prefixIcon: const Icon(Icons.admin_panel_settings, color: Color(0xFF63b14a)),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF63b14a)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF63b14a)),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF1e293b),
        items: const [
          DropdownMenuItem(
            value: 'auditor',
            child: Text(
              'Auditor',
              style: TextStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Text(
              'Administrador',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _selectedTipo = value!;
          });
        },
      ),
    );
  }
}
