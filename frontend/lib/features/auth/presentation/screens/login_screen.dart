import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/home/presentation/screens/home_dashboard.dart';
import 'package:frontend/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final String? message;
  const LoginScreen({super.key, this.message});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.message!),
            backgroundColor: AppTheme.primaryYellow,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.backgroundDark,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // Decoración de fondo
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Logo
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primaryYellow.withValues(alpha: 0.2),
                          width: 2,
                        ),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/logo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.oswald(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                            children: const [
                              TextSpan(text: 'SEMANUR '),
                              TextSpan(
                                text: 'HUB',
                                style: TextStyle(color: AppTheme.primaryYellow),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'GESTIÓN INTELIGENTE DE TALLER Y ACTIVOS',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textGray,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    'BIENVENIDO DE NUEVO',
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Inicia sesión para getionar el taller.',
                    style: TextStyle(color: AppTheme.textGray, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // Campos de texto
                  TextField(
                    controller: _emailController,
                    scrollPadding: const EdgeInsets.only(bottom: 100),
                    decoration: const InputDecoration(
                      labelText: 'CORREO ELECTRÓNICO',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    scrollPadding: const EdgeInsets.only(bottom: 100),
                    decoration: InputDecoration(
                      labelText: 'CONTRASEÑA',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppTheme.textGray,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Botón de Login
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final navigator = Navigator.of(context);
                              final messenger = ScaffoldMessenger.of(context);

                              // Ocultar teclado
                              FocusScope.of(context).unfocus();

                              // Validar campos vacíos
                              if (_emailController.text.trim().isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingrese su correo electrónico'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              if (_passwordController.text.isEmpty) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingrese su contraseña'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              try {
                                final success = await authProvider.login(
                                  _emailController.text,
                                  _passwordController.text,
                                );

                                if (!mounted) return;

                                if (success) {
                                  navigator.pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const HomeDashboard(),
                                    ),
                                  );
                                } else {
                                  // Mostrar error específico
                                  String errorMessage = authProvider.error ??
                                      'Credenciales incorrectas. Verifique su usuario y contraseña.';
                                  
                                  // Limpiar campo de contraseña
                                  _passwordController.clear();

                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: AppTheme.surfaceDark,
                                      title: const Text(
                                        'Error de Inicio de Sesión',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        errorMessage,
                                        style: const TextStyle(color: AppTheme.textGray),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text(
                                            'OK',
                                            style: TextStyle(color: AppTheme.primaryYellow),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor contacte con el area IT de Agropecuaria Juradó S.A.S. para restablecer su contraseña.',
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
