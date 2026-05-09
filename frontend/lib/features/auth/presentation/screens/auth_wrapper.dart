import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/home/presentation/screens/home_dashboard.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingAuth = true;
  String? _connectionMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runNormalAuth();
    });
  }

  Future<void> _runNormalAuth() async {
    setState(() {
      _isCheckingAuth = true;
      _connectionMessage = null;
    });

    final connectivity = await Connectivity().checkConnectivity();
    final hasConnection = connectivity != ConnectivityResult.none;

    if (!hasConnection) {
      setState(() {
        _connectionMessage = 'Sin conexion a internet. Verifica tu red.';
        _isCheckingAuth = false;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();
    if (mounted) {
      setState(() => _isCheckingAuth = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (_isCheckingAuth || auth.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A2E),
            body: Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          );
        }

        if (_connectionMessage != null) {
          return Scaffold(
            backgroundColor: const Color(0xFF1A1A2E),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.orange,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _connectionMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _runNormalAuth,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (auth.isAuthenticated) {
          return const HomeDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}

