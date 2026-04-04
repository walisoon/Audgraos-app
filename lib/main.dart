import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Carregar usuário salvo
  await AuthService.loadUserFromStorage();
  
  // Inicializar dados de exemplo
  await StorageService.inicializarDadosExemplo();
  
  runApp(const AgroClassApp());
}

class AgroClassApp extends StatelessWidget {
  const AgroClassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audgrãos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
