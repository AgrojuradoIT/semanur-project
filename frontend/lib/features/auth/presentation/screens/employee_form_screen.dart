import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/presentation/providers/employee_provider.dart';
import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:frontend/core/theme/app_theme.dart';

class EmployeeFormScreen extends StatefulWidget {
  final Empleado? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _documentoController;
  late TextEditingController _telefonoController;
  late TextEditingController _licenciaController;
  late TextEditingController _resumenController;

  String _selectedCargo = 'Operador';
  String _selectedDependencia = 'Operaciones';
  bool _isLoading = false;

  // User Access Fields
  bool _crearUsuario = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRoleUser = 'operador';

  final List<String> _cargos = [
    'Operador',
    'Mecánico',
    'Conductor',
    'Auxiliar',
    'Administrativo',
  ];
  final List<String> _dependencias = [
    'Operaciones',
    'Mantenimiento',
    'Administración',
    'Logística',
  ]; // Example values

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(
      text: widget.employee?.nombres ?? '',
    );
    _apellidosController = TextEditingController(
      text: widget.employee?.apellidos ?? '',
    );
    _documentoController = TextEditingController(
      text: widget.employee?.documento ?? '',
    );
    _telefonoController = TextEditingController(
      text: widget.employee?.telefono ?? '',
    );
    _licenciaController = TextEditingController(
      text: widget.employee?.licenciaConduccion ?? '',
    );
    _resumenController = TextEditingController(
      text: widget.employee?.resumenProfesional ?? '',
    );

    if (widget.employee?.cargo != null) {
      // Ensure the value exists in the list or add it
      if (!_cargos.contains(widget.employee!.cargo)) {
        _cargos.add(widget.employee!.cargo!);
      }
      _selectedCargo = widget.employee!.cargo!;
    }

    if (widget.employee?.dependencia != null) {
      if (!_dependencias.contains(widget.employee!.dependencia)) {
        _dependencias.add(widget.employee!.dependencia!);
      }
      _selectedDependencia = widget.employee!.dependencia!;
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    _licenciaController.dispose();
    _resumenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Intentando guardar...'),
        duration: Duration(milliseconds: 500),
      ),
    );

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de validación: revise los campos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> data = {
        'nombres': _nombresController.text,
        'apellidos': _apellidosController.text,
        'documento': _documentoController.text,
        'telefono': _telefonoController.text,
        'cargo': _selectedCargo,
        'dependencia': _selectedDependencia,
        'licencia_conduccion': _licenciaController.text.isNotEmpty
            ? _licenciaController.text
            : null,
        'resumen_profesional': _resumenController.text,
      };

      if (_crearUsuario && widget.employee == null) {
        data['crear_usuario'] = true;
        data['email'] = _emailController.text;
        data['password'] = _passwordController.text;
        data['role'] = _selectedRoleUser;
      }

      bool success;
      if (widget.employee == null) {
        success = await context.read<EmployeeProvider>().createEmployee(data);
      } else {
        success = await context.read<EmployeeProvider>().updateEmployee(
          widget.employee!.id,
          data,
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guardado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.read<EmployeeProvider>().error ?? 'Error al guardar',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employee == null ? 'NUEVO EMPLEADO' : 'EDITAR EMPLEADO',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información Personal'),
              _buildTextField(
                'Nombres',
                _nombresController,
                Icons.person,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Apellidos',
                _apellidosController,
                Icons.person_outline,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Documento Identidad',
                _documentoController,
                Icons.badge,
                required: true,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Teléfono',
                _telefonoController,
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Información Laboral'),
              DropdownButtonFormField<String>(
                initialValue: _selectedCargo,
                dropdownColor: AppTheme.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  prefixIcon: Icon(Icons.work, color: AppTheme.primaryYellow),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surfaceDark2),
                  ),
                ),
                items: _cargos
                    .map(
                      (cargo) =>
                          DropdownMenuItem(value: cargo, child: Text(cargo)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCargo = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDependencia,
                dropdownColor: AppTheme.surfaceDark,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Dependencia / Área',
                  prefixIcon: Icon(
                    Icons.business,
                    color: AppTheme.primaryYellow,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surfaceDark2),
                  ),
                ),
                items: _dependencias
                    .map(
                      (dep) => DropdownMenuItem(value: dep, child: Text(dep)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedDependencia = val!),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Licencia de Conducción',
                _licenciaController,
                Icons.card_membership,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'Resumen Profesional',
                _resumenController,
                Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              if (widget.employee == null) ...[
                _buildSectionTitle('Acceso al Sistema'),
                SwitchListTile(
                  title: const Text(
                    '¿Otorgar acceso a la App?',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _crearUsuario,
                  onChanged: (val) => setState(() => _crearUsuario = val),
                  activeThumbColor: AppTheme.primaryYellow,
                  contentPadding: EdgeInsets.zero,
                ),

                if (_crearUsuario) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Correo Electrónico',
                    _emailController,
                    Icons.email,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    'Contraseña',
                    _passwordController,
                    Icons.lock,
                    required: true,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoleUser,
                    dropdownColor: AppTheme.surfaceDark,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Rol de Usuario',
                      prefixIcon: Icon(
                        Icons.security,
                        color: AppTheme.primaryYellow,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.surfaceDark2),
                      ),
                    ),
                    items: ['admin', 'mecanico', 'operador', 'almacenista']
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedRoleUser = val!),
                  ),
                ],
              ],

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'GUARDAR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    bool isPassword = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: required
          ? (val) => val == null || val.isEmpty ? 'Campo requerido' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textGray),
        prefixIcon: Icon(icon, color: AppTheme.primaryYellow),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.surfaceDark2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryYellow),
        ),
      ),
    );
  }
}
