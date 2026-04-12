import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'clientes_list_screen.dart';
import 'ordens_servico_screen.dart';
import 'laudos_list_screen.dart';
import 'laudos_copia_screen.dart';
import 'nova_ordem_servico_screen.dart';
import 'classificacao_laudo_screen.dart';
import 'usuarios_screen.dart';
import 'sync_screen.dart';
import '../services/auth_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String selectedItem = '';

  Future<void> _navigateTo(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> handleMenuPress(String itemId) async {
    setState(() {
      selectedItem = itemId;
    });

    Widget? page;
    switch (itemId) {
      case 'ordens':
        page = const OrdensServicoScreen();
        break;
      case 'clientes':
        page = const ClientesListScreen();
        break;
      case 'laudos':
        page = const LaudosListScreen();
        break;
      case 'laudos_copia':
        page = const LaudosCopiaScreen();
        break;
      case 'usuarios':
        page = const UsuariosScreen();
        break;
      case 'sync':
        page = const SyncScreen();
        break;
    }

    if (page != null) {
      await _navigateTo(page);
    }

    if (!mounted) return;
    setState(() {
      selectedItem = '';
    });
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
          child: Stack(
            children: [
              // Background glow effect
              Positioned(
                top: -160,
                left: -0.25 * MediaQuery.of(context).size.width,
                child: Container(
                  width: 1.5 * MediaQuery.of(context).size.width,
                  height: 380,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(700),
                    color: const Color(0xFF63b14a).withOpacity(0.15),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF63b14a).withOpacity(0.3),
                        offset: const Offset(0, 20),
                        blurRadius: 80,
                      ),
                    ],
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Logo e textos sem header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Logo direto
                          Hero(
                            tag: 'logo',
                            child: Image.asset(
                              'assets/images/logo sem fundo.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          
                          const SizedBox(height: 5),
                          
                          const Text(
                            'Bem-vindo',
                            style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFcbd5e1),
                            ),
                          ),
                          
                          const SizedBox(height: 2),
                          
                          const Text(
                            'Sistema de Auditoria de Grãos',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFcbd5e1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu grid com scroll
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 65),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: menuItems.map((item) {
                                return SizedBox(
                                  width: (MediaQuery.of(context).size.width - 56) / 2,
                                  height: 160,
                                  child: ActionButton(
                                    item: item,
                                    isSelected: selectedItem == item.id,
                                    onPressed: () => handleMenuPress(item.id),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 40),
                            
                            // App version at bottom
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Versão 1.0.0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  MenuItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

List<MenuItem> get menuItems {
  List<MenuItem> items = [
    MenuItem(
      id: 'ordens',
      title: 'Ordens de Serviço',
      icon: Icons.assignment,
      color: const Color(0xFF63b14a),
    ),
    MenuItem(
      id: 'clientes',
      title: 'Clientes',
      icon: Icons.people,
      color: const Color(0xFF3b82f6),
    ),
        MenuItem(
      id: 'laudos',
      title: 'Laudos',
      icon: Icons.description,
      color: const Color(0xFFf59e0b),
    ),
    MenuItem(
      id: 'laudos_copia',
      title: 'Auditorias',
      icon: Icons.assessment,
      color: const Color(0xFF8b5cf6),
    ),
  ];

  // Adicionar opção Usuários apenas para administradores
  if (AuthService.podeAcessarUsuarios()) {
    items.add(MenuItem(
      id: 'usuarios',
      title: 'Usuários',
      icon: Icons.admin_panel_settings,
      color: const Color(0xFFef4444),
    ));
  }

  // Adicionar opção de sincronização para todos
  items.add(MenuItem(
    id: 'sync',
    title: 'Sincronizar',
    icon: Icons.cloud_sync,
    color: const Color(0xFF06b6d4),
  ));

  return items;
}

class ActionButton extends StatelessWidget {
  final MenuItem item;
  final bool isSelected;
  final VoidCallback onPressed;

  const ActionButton({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [item.color.withOpacity(0.8), item.color.withOpacity(0.6)]
                : [const Color(0xFF1e293b), const Color(0xFF334155)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? item.color.withOpacity(0.4)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? item.color.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? item.color.withOpacity(0.2)
                    : item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.icon,
                size: 32,
                color: isSelected ? item.color : item.color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? item.color : Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
