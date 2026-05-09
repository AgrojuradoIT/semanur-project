import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // DUMMY IMPLEMENTATION - Replace with actual Auth logic
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente (Simulado)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SemanurScaffold(
      backgroundColor: AppTheme.backgroundDark,
      currentNav: SemanurNavItem.profile,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CAMBIAR CONTRASEÑA',
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildPasswordField(
                label: 'Contraseña Actual',
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                onToggleVisibility: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                label: 'Nueva Contraseña',
                controller: _newPasswordController,
                obscureText: _obscureNew,
                onToggleVisibility: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (value.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                label: 'Confirmar Nueva Contraseña',
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onToggleVisibility: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppTheme.surfaceDark,
                        )
                      : Text(
                          'ACTUALIZAR CONTRASEÑA',
                          style: GoogleFonts.inter(
                            color: AppTheme.surfaceDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: AppTheme.primaryYellow,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.white38,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryYellow),
        ),
      ),
    );
  }
}
