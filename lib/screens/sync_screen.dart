import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  SyncStatus _currentStatus = SyncStatus.idle;
  String _lastSyncText = 'Nunca sincronizado';
  SyncResult? _lastResult;

  @override
  void initState() {
    super.initState();
    _loadLastSyncInfo();
    _listenToSyncStatus();
    SyncService.startAutoSyncMonitoring();
  }

  @override
  void dispose() {
    SyncService.dispose();
    super.dispose();
  }

  void _loadLastSyncInfo() async {
    final lastSync = await SyncService.getLastSyncTimestamp();
    setState(() {
      if (lastSync != null) {
        _lastSyncText = DateFormat('dd/MM/yyyy HH:mm').format(lastSync);
      }
    });
  }

  void _listenToSyncStatus() {
    SyncService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
      });
    });
  }

  Future<void> _syncManual() async {
    final result = await SyncService.syncManual();
    setState(() {
      _lastResult = result;
    });
    
    _loadLastSyncInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _forceFullSync() async {
    // Confirmar ação
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text('Confirmar Sincronização Forçada', 
          style: TextStyle(color: Colors.white)),
        content: const Text(
          'Isso irá forçar o upload de todos os dados locais para a nuvem. Deseja continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', 
              style: TextStyle(color: Color(0xFF63b14a))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Forçar', 
              style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await SyncService.forceFullSync();
      setState(() {
        _lastResult = result;
      });
      
      _loadLastSyncInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
          'Sincronização de Dados',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status atual
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getStatusColor().withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(),
                        color: _getStatusColor(),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Última sincronização: $_lastSyncText',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botões de sincronização
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF63b14a).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ações de Sincronização',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sincronização manual
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentStatus == SyncStatus.syncing ? null : _syncManual,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF63b14a),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _currentStatus == SyncStatus.syncing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Sincronizando...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            'Sincronizar Agora',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Sincronização forçada
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentStatus == SyncStatus.syncing ? null : _forceFullSync,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Forçar Sincronização Completa',
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
            
            const SizedBox(height: 24),
            
            // Informações
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1e293b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Como Funciona',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoItem(
                    'Sincronização Manual',
                    'Envia todos os dados pendentes para a nuvem',
                  ),
                  _buildInfoItem(
                    'Sincronização Automática',
                    'O app verifica a cada 30 segundos e sincroniza quando online',
                  ),
                  _buildInfoItem(
                    'Forçar Sincronização',
                    'Força o upload de TODOS os dados locais, mesmo que já estejam na nuvem',
                  ),
                ],
              ),
            ),
            
            // Resultado da última sincronização
            if (_lastResult != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _lastResult!.success ? 
                    const Color(0xFF63b14a).withOpacity(0.1) : 
                    Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _lastResult!.success ? 
                      const Color(0xFF63b14a) : 
                      Colors.red,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resultado da Última Sincronização',
                      style: TextStyle(
                        color: _lastResult!.success ? 
                          const Color(0xFF63b14a) : 
                          Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _lastResult!.message,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_lastResult!.details != null) ...[
                      const SizedBox(height: 8),
                      ..._lastResult!.details!.entries.map((entry) =>
                        Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case SyncStatus.syncing:
        return Icons.sync;
      case SyncStatus.success:
        return Icons.check_circle;
      case SyncStatus.error:
        return Icons.error;
      case SyncStatus.offline:
        return Icons.wifi_off;
      default:
        return Icons.cloud;
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return const Color(0xFF63b14a);
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.orange;
      default:
        return Colors.white;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.success:
        return 'Sincronizado com sucesso';
      case SyncStatus.error:
        return 'Erro na sincronização';
      case SyncStatus.offline:
        return 'Offline';
      default:
        return 'Aguardando sincronização';
    }
  }
}
