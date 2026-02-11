import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _placaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _kmController = TextEditingController();
  final _horometroController = TextEditingController();

  String? _selectedType;
  DateTime? _soatDate;
  DateTime? _tecnoDate;

  final List<String> _vehicleTypes = [
    'Tractor',
    'Volqueta',
    'Camioneta',
    'Moto',
    'Maquinaria',
    'Otro',
  ];

  @override
  void dispose() {
    _placaController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _kmController.dispose();
    _horometroController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isSoat) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryYellow,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isSoat) {
          _soatDate = picked;
        } else {
          _tecnoDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor seleccione un tipo de vehículo'),
        ),
      );
      return;
    }

    final provider = context.read<FleetProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final Map<String, dynamic> data = {
      'placa': _placaController.text.toUpperCase(),
      'marca': _marcaController.text,
      'modelo': _modeloController.text,
      'tipo': _selectedType,
      'kilometraje_actual': double.tryParse(_kmController.text) ?? 0,
      'horometro_actual': double.tryParse(_horometroController.text) ?? 0,
      'fecha_vencimiento_soat': _soatDate?.toIso8601String().split('T')[0],
      'fecha_vencimiento_tecnomecanica': _tecnoDate?.toIso8601String().split(
        'T',
      )[0],
      // Parámetros por defecto
      'estado': 'Activo',
      'horometro_proximo_mantenimiento':
          (double.tryParse(_horometroController.text) ?? 0) + 250, // Ejemplo
      'kilometraje_proximo_mantenimiento':
          (double.tryParse(_kmController.text) ?? 0) + 5000, // Ejemplo
    };

    final success = await provider.createVehicle(data);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'VEHÍCULO ${_placaController.text.toUpperCase()} CREADO',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error ?? "Desconocido"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FleetProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          'REGISTRAR NUEVO VEHÍCULO',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('INFORMACIÓN GENERAL'),
              _buildTextField(
                'Placa',
                _placaController,
                icon: Icons.tag,
                isRequired: true,
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Marca',
                      _marcaController,
                      icon: Icons.branding_watermark,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      'Modelo',
                      _modeloController,
                      icon: Icons.model_training,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildTypeDropdown(),

              const SizedBox(height: 30),
              _buildSectionTitle('LECTURAS INICIALES'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      'Kilometraje',
                      _kmController,
                      icon: Icons.speed,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildTextField(
                      'Horómetro',
                      _horometroController,
                      icon: Icons.timer,
                      isNumber: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              _buildSectionTitle('VENCIMIENTOS DOCUMENTALES'),
              _buildDatePicker(
                'Vencimiento SOAT',
                _soatDate,
                () => _selectDate(context, true),
              ),
              const SizedBox(height: 15),
              _buildDatePicker(
                'Vencimiento Tecnomecánica',
                _tecnoDate,
                () => _selectDate(context, false),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: AppTheme.primaryYellow.withValues(alpha: 0.3),
                  ),
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'GUARDAR VEHÍCULO',
                          style: GoogleFonts.oswald(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryYellow,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool isNumber = false,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textGray),
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.textGray, size: 20)
            : null,
        filled: true,
        fillColor: AppTheme.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.surfaceDark2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryYellow),
        ),
      ),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Campo requerido';
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          hint: const Text(
            'Tipo de Vehículo',
            style: TextStyle(color: AppTheme.textGray),
          ),
          dropdownColor: AppTheme.surfaceDark,
          isExpanded: true,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppTheme.primaryYellow,
          ),
          style: const TextStyle(color: Colors.white),
          items: _vehicleTypes.map((String type) {
            return DropdownMenuItem<String>(value: type, child: Text(type));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedType = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceDark2),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppTheme.textGray,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.white24,
                      fontWeight: date != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
