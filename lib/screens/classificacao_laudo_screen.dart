import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auditorias_screen.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import 'laudos_list_screen.dart';

class ClassificacaoLaudoScreen extends StatefulWidget {
  final String ordemNumero;
  final String servico;

  const ClassificacaoLaudoScreen({
    super.key,
    required this.ordemNumero,
    required this.servico,
  });

  @override
  State<ClassificacaoLaudoScreen> createState() => _ClassificacaoLaudoScreenState();
}

class _ClassificacaoLaudoScreenState extends State<ClassificacaoLaudoScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Dados da Auditoria
  final _origemController = TextEditingController();
  final _destinoController = TextEditingController();
  final _notaFiscalController = TextEditingController();
  final _produtoController = TextEditingController();
  final _clienteController = TextEditingController();
  final _placaController = TextEditingController();
  final _divergenciaController = TextEditingController();
  final _tipoController = TextEditingController();
  final _terminalRecusaController = TextEditingController();
  final _resultadoController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _certificadoraController = TextEditingController();
  final _pesoController = TextEditingController();
  final _transportadoraController = TextEditingController();
  final _nomeClassificadorController = TextEditingController();
  
  String? _odor;
  String? _sementes;
  
  final List<String> _odorOptions = ['Sim', 'Não'];
  final List<String> _sementesOptions = ['Sim', 'Não'];

  @override
  void dispose() {
    _origemController.dispose();
    _destinoController.dispose();
    _notaFiscalController.dispose();
    _produtoController.dispose();
    _clienteController.dispose();
    _placaController.dispose();
    _divergenciaController.dispose();
    _tipoController.dispose();
    _terminalRecusaController.dispose();
    _resultadoController.dispose();
    _observacoesController.dispose();
    _certificadoraController.dispose();
    _pesoController.dispose();
    _transportadoraController.dispose();
    _nomeClassificadorController.dispose();
    super.dispose();
  }

  Future<void> _gerarPdf() async {
    if (_formKey.currentState!.validate()) {
      final laudoData = {
        'id': widget.ordemNumero,
        'servico': widget.servico,
        'data': DateTime.now().toString().split(' ')[0],
        'status': 'Concluído',
        
        // Dados da Auditoria
        'origem': _origemController.text,
        'destino': _destinoController.text,
        'notaFiscal': _notaFiscalController.text,
        'produto': _produtoController.text,
        'cliente': _clienteController.text,
        'placa': _placaController.text,
        'certificadora': _certificadoraController.text,
        'peso': _pesoController.text,
        'transportadora': _transportadoraController.text,
        'nomeClassificador': _nomeClassificadorController.text,
        'divergencia': _divergenciaController.text,
        'tipo': _tipoController.text,
        'terminalRecusa': _terminalRecusaController.text,
        'resultado': _resultadoController.text,
        
        // Campos mantidos
        'odor': _odor,
        'sementes': _sementes,
        'observacoes': _observacoesController.text,
      };

      try {
        await PdfService.gerarPdfLaudo(laudoData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white),
                SizedBox(width: 8),
                Text('PDF gerado com sucesso!'),
              ],
            ),
            backgroundColor: Color(0xFF63b14a),
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
    }
  }

  Future<void> _salvarLaudo() async {
    if (_formKey.currentState!.validate()) {
      final laudoData = {
        'id': '', // ID será gerado automaticamente
        'servico': widget.servico,
        'data': DateTime.now().toString().split(' ')[0],
        'status': 'Concluído',
        
        // Dados da Auditoria
        'origem': _origemController.text,
        'destino': _destinoController.text,
        'notaFiscal': _notaFiscalController.text,
        'produto': _produtoController.text,
        'cliente': _clienteController.text,
        'placa': _placaController.text,
        'certificadora': _certificadoraController.text,
        'peso': _pesoController.text,
        'transportadora': _transportadoraController.text,
        'nomeClassificador': _nomeClassificadorController.text,
        'divergencia': _divergenciaController.text,
        'tipo': _tipoController.text,
        'terminalRecusa': _terminalRecusaController.text,
        'resultado': _resultadoController.text,
        
        // Campos mantidos
        'odor': _odor,
        'sementes': _sementes,
        'observacoes': _observacoesController.text,
      };

      try {
        // Salvar laudo no StorageService
        debugPrint('=== SALVANDO LAUDO ===');
        debugPrint('Dados do laudo: $laudoData');
        await StorageService.adicionarLaudo(laudoData);
        debugPrint('Laudo salvo com sucesso!');
        
        // Adicionar laudo à tela de auditorias
        AuditoriasScreen.adicionarLaudo(laudoData);
        
        // Atualizar lista de laudos automaticamente
        LaudosListScreen.adicionarLaudo(laudoData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Laudo salvo no dispositivo com sucesso!'),
              ],
            ),
            backgroundColor: Color(0xFF63b14a),
            duration: Duration(seconds: 3),
          ),
        );

        // Navegar de volta após 2 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao salvar laudo. Tente novamente.'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
        toolbarHeight: 110,
        leadingWidth: 100,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 12, bottom: 12),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              size: 24,
              color: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.08),
                const Color(0xFF63b14a).withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFF63b14a).withOpacity(0.25),
                blurRadius: 35,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF63b14a).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'LAUDO DE AUDITORIA',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.5,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                      Shadow(
                        color: Color(0xFF63b14a),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF061126),
                const Color(0xFF0a1b30),
                const Color(0xFF0f172a),
                const Color(0xFF1a2332),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: const Color(0xFF63b14a).withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 14),
                  const Text(
                    'Preencha os dados abaixo para concluir o laudo',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  
                  // Dados da Auditoria
                  _buildSectionCard('Dados da Auditoria', [
                    _buildTextField('Origem', _origemController, Icons.location_on),
                    _buildTextField('Destino', _destinoController, Icons.flag),
                    _buildTextField('Nota Fiscal', _notaFiscalController, Icons.receipt),
                    _buildTextField('Produto', _produtoController, Icons.inventory),
                    _buildTextField('Cliente', _clienteController, Icons.person),
                    _buildTextField('Placa do Veículo', _placaController, Icons.directions_car),
                    _buildTextField('Peso', _pesoController, Icons.monitor_weight),
                    _buildTextField('Transportadora', _transportadoraController, Icons.local_shipping),
                    _buildTextField('Nome do Classificador Responsável', _nomeClassificadorController, Icons.person),
                    _buildTextField('Certificadora Responsável', _certificadoraController, Icons.verified_user),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Divergência Identificada
                  _buildSectionCard('Divergência Identificada', [
                    _buildTextField('Tipo', _tipoController, Icons.category),
                    _buildTextField('Descrição', _divergenciaController, Icons.warning),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Resultados
                  _buildSectionCard('Resultados', [
                    _buildTextField('Terminal Recusa', _terminalRecusaController, Icons.block),
                    _buildTextField('Resultado Auditoria', _resultadoController, Icons.assessment),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Análises (campos mantidos)
                  _buildSectionCard('Análises', [
                    _buildDropdown('Odor', _odor, _odorOptions, Icons.sensors),
                    _buildDropdown('Sementes', _sementes, _sementesOptions, Icons.grain),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Observações
                  _buildSectionCard('Observações', [
                    _buildTextArea('Observações', _observacoesController),
                  ]),
                  
                  const SizedBox(height: 30),
                  
                  // Botões de Ação
                  Row(
                    children: [
                      // Botão GERAR PDF oculto
                      // Expanded(
                      //   child: ElevatedButton(
                      //     onPressed: _gerarPdf,
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.orange,
                      //       padding: const EdgeInsets.symmetric(vertical: 16),
                      //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      //       elevation: 4,
                      //       shadowColor: Colors.orange.withOpacity(0.3),
                      //     ),
                      //     child: const Row(
                      //       mainAxisAlignment: MainAxisAlignment.center,
                      //       children: [
                      //         Icon(Icons.picture_as_pdf, size: 20),
                      //         SizedBox(width: 8),
                      //         Text(
                      //           'GERAR PDF',
                      //           style: TextStyle(
                      //             color: Colors.white,
                      //             fontWeight: FontWeight.w600,
                      //             fontSize: 16,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      // const SizedBox(width: 16),
                      
                      // Apenas o botão SALVAR LAUDO permanece
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _salvarLaudo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF63b14a),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                            shadowColor: const Color(0xFF63b14a).withOpacity(0.3),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'SALVAR LAUDO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF63b14a).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description,
                  color: Color(0xFF63b14a),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordem: ${widget.ordemNumero}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.servico,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1e293b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF63b14a),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
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
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, informe $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
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
        style: const TextStyle(color: Colors.white),
        dropdownColor: const Color(0xFF1e293b),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(
              option,
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            if (label == 'Odor') {
              _odor = value;
            } else if (label == 'Sementes') {
              _sementes = value;
            }
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Por favor, selecione $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildTextArea(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFcbd5e1)),
        prefixIcon: const Icon(Icons.note, color: Color(0xFF63b14a)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF63b14a)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF63b14a)),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
    );
  }
}
