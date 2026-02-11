import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:frontend/features/scheduler/presentation/providers/programacion_provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:provider/provider.dart';

class IncidentReportScreen extends StatefulWidget {
  final User? preSelectedEmployee;
  final DateTime? preSelectedDate;

  const IncidentReportScreen({
    super.key,
    this.preSelectedEmployee,
    this.preSelectedDate,
  });

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  // Theme Colors based on design
  static const Color primaryColor = Color(0xFFF20D0D); // Red

  static const Color backgroundDark = Color(0xFF1E1E1E);
  static const Color surfaceDark = Color(0xFF2C2C2C);
  static const Color textSecondary = Color(0xFF9E9E9E);

  bool isUrgent = true;
  bool pauseActivity = false;
  final TextEditingController _descriptionController = TextEditingController();
  User? _selectedEmployee;
  Vehiculo? _selectedVehicle;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _selectedEmployee = widget.preSelectedEmployee;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  void _submitReport() async {
    if (_selectedEmployee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor seleccione un empleado')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese una descripción')),
      );
      return;
    }

    final fullDescription = _descriptionController.text;

    try {
      final provider = context.read<ProgramacionProvider>();
      final empleadoBackendId = _selectedEmployee!.id; // Ya no usamos userId

      final error = await provider.reportarNovedad(
        fecha: widget.preSelectedDate ?? DateTime.now(),
        empleadoId: empleadoBackendId,
        vehiculoId: _selectedVehicle?.id,
        descripcion: fullDescription,
        prioridad: isUrgent ? 'URGENTE' : 'NORMAL',
        pausarActividad: pauseActivity,
        localImagePath: _imageFile?.path,
      );

      if (mounted) {
        if (error == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Novedad reportada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                children: [
                  _buildEmployeeSelector(),
                  const SizedBox(height: 16),
                  _buildVehicleSelector(),
                  const SizedBox(height: 24),
                  _buildPrioritySection(),
                  const SizedBox(height: 24),
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),
                  _buildOptionsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: Text(
              'REPORTE DE NOVEDAD',
              textAlign: TextAlign.center,
              style: GoogleFonts.oswald(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 40), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector() {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMPLEADO AFECTADO',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<User>(
                  value: _selectedEmployee,
                  hint: const Text(
                    'Seleccionar empleado',
                    style: TextStyle(color: Colors.white54),
                  ),
                  isExpanded: true,
                  dropdownColor: surfaceDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                  items: provider.users.map((User u) {
                    return DropdownMenuItem<User>(
                      value: u,
                      child: Text(
                        u.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedEmployee = val;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleSelector() {
    return Consumer<FleetProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VEHÍCULO (OPCIONAL)',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Vehiculo>(
                  value: _selectedVehicle,
                  hint: const Text(
                    'Ninguno / Personal',
                    style: TextStyle(color: Colors.white54),
                  ),
                  isExpanded: true,
                  dropdownColor: surfaceDark,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white54,
                  ),
                  items: [
                    const DropdownMenuItem<Vehiculo>(
                      value: null,
                      child: Text(
                        'Ninguno / Personal',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ...provider.vehiculos.map((Vehiculo v) {
                      return DropdownMenuItem<Vehiculo>(
                        value: v,
                        child: Text(
                          '${v.placa} - ${v.modelo}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedVehicle = val;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NIVEL DE PRIORIDAD',
          style: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isUrgent = false),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isUrgent
                          ? const Color(0xFF404040)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Normal',
                      style: GoogleFonts.inter(
                        color: !isUrgent ? Colors.white : textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => isUrgent = true),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isUrgent ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isUrgent
                          ? [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isUrgent) ...[
                          const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          'URGENTE',
                          style: GoogleFonts.inter(
                            color: isUrgent ? Colors.white : textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'DESCRIPCIÓN DEL INCIDENTE',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            TextButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(
                Icons.add_a_photo,
                size: 14,
                color: primaryColor,
              ),
              label: Text(
                'Adjuntar Foto',
                style: GoogleFonts.inter(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_imageFile != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _imageFile!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          decoration: BoxDecoration(
            color: surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: 6,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describa la novedad o impedimento detalladamente... Ej: El equipo presenta una fuga en la válvula principal...',
              hintStyle: GoogleFonts.inter(
                color: textSecondary.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pause_circle_filled,
              color: primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pausar Actividad Actual',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Detiene el cronómetro de la tarea en curso',
                  style: GoogleFonts.inter(color: textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: pauseActivity,
            activeThumbColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF404040),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: (val) => setState(() => pauseActivity = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: primaryColor.withValues(alpha: 0.4),
              ).copyWith(elevation: WidgetStateProperty.all(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'REGISTRAR NOVEDAD',
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ID de Sesión: #SH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            style: GoogleFonts.inter(
              color: textSecondary.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
