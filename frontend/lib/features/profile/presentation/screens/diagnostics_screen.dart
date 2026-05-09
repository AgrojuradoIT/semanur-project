import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  final List<String> _logs = [];
  bool _diagDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runDiagnostics();
    });
  }

  void _addLog(String msg) {
    if (mounted) {
      setState(() {
        _logs.add('[${DateTime.now().toIso8601String().substring(11, 19)}] $msg');
      });
    }
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _diagDone = false;
      _logs.clear();
    });

    _addLog('Iniciando diagnostico manual...');

    // 1. Check .env
    final apiUrl = dotenv.env['API_URL'] ?? 'NO DEFINIDA';
    _addLog('API_URL: $apiUrl');

    // 2. Check stored token
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final token = await storage.read(key: 'auth_token');
    _addLog('Token almacenado: ${token != null ? "SI (${token.length} chars)" : "NO"}');

    final cachedUser = await storage.read(key: 'user_data');
    _addLog('Cache usuario: ${cachedUser != null ? "SI" : "NO"}');

    // 3. Quick connectivity test to backend (Anonymous)
    _addLog('Probando conexion ANONIMA a backend...');
    try {
      final testDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      final response1 = await testDio.get('$apiUrl/user');
      _addLog('Respuesta anonima: ${response1.statusCode}');
    } on DioException catch (e) {
      _addLog('Anonima fallida: ${e.response?.statusCode} - ${e.message}');
    }

    // 4. Authenticated Request Test
    if (token != null && token.isNotEmpty) {
      _addLog('Probando conexion AUTENTICADA (/productos)...');
      try {
        final authDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));
        final response2 = await authDio.get('$apiUrl/productos');
        _addLog('Exito autenticado: ${response2.statusCode}');
        _addLog('Data length: ${response2.data?.toString().length}');
      } on DioException catch (e) {
        if (e.response != null) {
          _addLog('ERROR backend: HTTP ${e.response?.statusCode}');
          _addLog('Response: ${e.response?.data?.toString().substring(0, 50)}');
        } else {
          _addLog('ERROR red/dio: ${e.type.name} - ${e.message}');
        }
      } catch (e) {
        _addLog('ERROR critico: $e');
      }
    }

    if (mounted) {
      setState(() {
        _diagDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Diagnóstico de Conexión', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!_diagDone)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                    ),
                  if (!_diagDone) const SizedBox(width: 12),
                  Text(
                    _diagDone ? '✅ Diagnóstico completo' : '⏳ Diagnosticando red...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Semanur HUB - Pruebas HTTP crudas',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      Color color = Colors.white70;
                      if (log.contains('ERROR')) color = Colors.redAccent;
                      if (log.contains('SI') || log.contains('accesible') || log.contains('completado')) {
                        color = Colors.greenAccent;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: color,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_diagDone)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _runDiagnostics,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Limpiar y Reintentar', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
