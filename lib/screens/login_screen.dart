import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'menu_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _lembrarSenha = false;
  bool _senhaVisivel = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarCredenciaisSalvas();
  }

  Future<void> _carregarCredenciaisSalvas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailSalvo = prefs.getString('lembrar_email');
      final senhaSalva = prefs.getString('lembrar_senha');
      
      if (emailSalvo != null && senhaSalva != null) {
        setState(() {
          _emailController.text = emailSalvo;
          _senhaController.text = senhaSalva;
          _lembrarSenha = true;
        });
      }
    } catch (e) {
      print('Erro ao carregar credenciais salvas: $e');
    }
  }

  Future<void> _salvarCredenciais() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lembrarSenha) {
        await prefs.setString('lembrar_email', _emailController.text.trim());
        await prefs.setString('lembrar_senha', _senhaController.text);
      } else {
        await prefs.remove('lembrar_email');
        await prefs.remove('lembrar_senha');
      }
    } catch (e) {
      print('Erro ao salvar credenciais: $e');
    }
  }

  Future<void> _fazerLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Autenticação com email e senha
        final user = await AuthService.signInWithEmail(
          _emailController.text.trim(),
          _senhaController.text,
        );

        if (user != null) {
          // Salvar credenciais se lembrar estiver marcado
          await _salvarCredenciais();
          
          // Login bem sucedido
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MenuScreen(),
              ),
            );
          }
        } else {
          // Falha no login
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email ou senha inválidos'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Tratamento de erros simulados
        String errorMessage = 'Erro ao fazer login';
        
        // Simular diferentes tipos de erro baseado na entrada
        if (_emailController.text.contains('error')) {
          errorMessage = 'Usuário não encontrado';
        } else if (_senhaController.text.contains('error')) {
          errorMessage = 'Senha incorreta';
        } else if (!_emailController.text.contains('@')) {
          errorMessage = 'Email inválido';
        } else if (_senhaController.text.length < 6) {
          errorMessage = 'Senha deve ter pelo menos 6 caracteres';
        } else {
          errorMessage = 'Erro desconhecido. Tente novamente.';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fazerLoginGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Login com Google
      final user = await AuthService.signInWithGoogle();

      if (user != null) {
        // Login bem sucedido
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bem-vindo, ${user.displayName ?? user.email}!'),
              backgroundColor: const Color(0xFF63b14a),
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MenuScreen(),
            ),
          );
        }
      } else {
        // Usuário cancelou o login
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login com Google cancelado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro no login com Google: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0a0e27),
                Color(0xFF151932),
                Color(0xFF1a1f3a),
                Color(0xFF0f172a),
              ],
            ),
            image: DecorationImage(
              image: AssetImage('imagem/porto.png'),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: Stack(
            children: [
              // Elementos de fundo animados
              _buildBackgroundElements(),
              
              // Conteúdo principal
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Logo e título
                        _buildLogoSection(),
                        
                        const SizedBox(height: 16),
                        
                        // Card de login
                        _buildLoginCard(),
                        
                        const SizedBox(height: 20),
                        
                        // Links adicionais
                        _buildAdditionalLinks(),
                        
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Círculos decorativos
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.withOpacity(0.2),
                  Colors.cyan.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Grade de pontos futurista
        ...List.generate(20, (index) {
          final x = (index % 5) * 80.0 + 40;
          final y = (index ~/ 5) * 120.0 + 100;
          return Positioned(
            left: x,
            top: y,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Logo personalizado
        Hero(
          tag: 'logo',
          child: Container(
            width: 200,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo sem fundo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          'Sistema de Auditoria de Grãos',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFF63b14a).withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Título do card
            const Text(
              'ACESSAR SISTEMA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Campo de email
            _buildEmailField(),
            
            const SizedBox(height: 8),
            
            // Campo de senha
            _buildPasswordField(),
            
            const SizedBox(height: 10),
            
            // Lembrar senha e esqueci senha
            Row(
              children: [
                _buildRememberMeCheckbox(),
                const Spacer(),
                _buildForgotPasswordLink(),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Botão de login
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Color(0xFF63b14a),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF63b14a),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe seu email';
        }
        if (!value.contains('@')) {
          return 'Email inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _senhaController,
      obscureText: !_senhaVisivel,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Senha',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Color(0xFF63b14a),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _senhaVisivel ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withOpacity(0.7),
          ),
          onPressed: () {
            setState(() {
              _senhaVisivel = !_senhaVisivel;
            });
          },
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF63b14a),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe sua senha';
        }
        if (value.length < 6) {
          return 'Senha deve ter pelo menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _lembrarSenha ? const Color(0xFF63b14a) : Colors.white.withOpacity(0.3),
            ),
            color: _lembrarSenha ? const Color(0xFF63b14a) : Colors.transparent,
          ),
          child: _lembrarSenha
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _lembrarSenha = !_lembrarSenha;
            });
          },
          child: Text(
            'Lembrar senha',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: () async {
        final email = _emailController.text.trim();
        
        if (email.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Digite seu email primeiro'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        try {
          await AuthService.resetPassword(email);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email de redefinição enviado para $email'),
                backgroundColor: const Color(0xFF63b14a),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro ao enviar email de redefinição'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: const Text(
        'Esqueci a senha',
        style: TextStyle(
          color: Color(0xFF63b14a),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _fazerLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF63b14a),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: const Color(0xFF63b14a).withOpacity(0.3),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('AUTENTICANDO...'),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ENTRAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAdditionalLinks() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OU',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Link para cadastro
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Não tem uma conta? ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Implementar tela de cadastro
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento'),
                    backgroundColor: Color(0xFF63b14a),
                  ),
                );
              },
              child: const Text(
                'Cadastre-se',
                style: TextStyle(
                  color: Color(0xFF63b14a),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDemoUsers() {
    final users = AuthService.getPredefinedUsers();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Usuários de Demonstração',
            style: TextStyle(
              color: Color(0xFF63b14a),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Use os seguintes usuários para testar:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...users.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF63b14a).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key == 'jailson@audgraos.com' ? 'Administrador' : 'Usuário',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF63b14a),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Email: ${entry.key}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Senha: ${entry.value}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(color: Color(0xFF63b14a)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton(String text, IconData icon, Color color) {
    return OutlinedButton(
      onPressed: text == 'Google' ? _fazerLoginGoogle : () {
        // TODO: Implementar login Microsoft
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login $text em desenvolvimento'),
            backgroundColor: color,
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: _isLoading && text == 'Google'
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'CARREGANDO...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
