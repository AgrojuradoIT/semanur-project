import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/data/models/checklist_model.dart';
import 'package:frontend/features/fleet/presentation/providers/checklist_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChecklistScreen extends StatefulWidget {
  final Vehiculo vehiculo;

  const ChecklistScreen({super.key, required this.vehiculo});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _horometroController = TextEditingController();
  final _observacionesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Map<String, bool> _checklistAnswers = {};
  Map<String, List<String>> _currentItems = {};

  bool get _isAerial => widget.vehiculo.tipo.toLowerCase().contains('aereo');
  bool get _isTractor => widget.vehiculo.tipo.toLowerCase().contains('tractor');

  @override
  void initState() {
    super.initState();
    _loadChecklistItems();
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Optimize size
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  void _loadChecklistItems() {
    // Definición de Items segun tipo
    // Tractor Aéreo: Solo Aceite y Filtro
    if (_isAerial) {
      _currentItems = {
        'Mantenimiento Crítico': [
          'Nivel de Aceite de Motor',
          'Estado del Filtro de Aire',
          'Fugas de Aceite',
        ],
      };
    }
    // Tractores Agricolas
    else if (_isTractor) {
      _currentItems = {
        'Niveles y Fluidos': [
          'Aceite de Motor',
          'Refrigerante / Agua',
          'Aceite Hidráulico',
          'Combustible (Drenaje de agua)',
        ],
        'Sistema Eléctrico': [
          'Batería y Bornes',
          'Luces de Trabajo',
          'Tablero de Instrumentos',
        ],
        'Mecánica y Llantas': [
          'Presión de Llantas',
          'Puntos de Engrase',
          'Frenos',
        ],
      };
    }
    // Volquetas y Vehículos Pesados
    else {
      _currentItems = {
        'Niveles': [
          'Aceite de Motor',
          'Refrigerante',
          'Líquido de Frenos',
          'Dirección Hidráulica',
        ],
        'Llantas': [
          'Presión y Estado',
          'Pernos Completos',
          'Llanta de Repuesto',
        ],
        'Luces y Eléctrico': [
          'Altas y Bajas',
          'Stop y Direccionales',
          'Pito / Bocina',
        ],
        'Seguridad': [
          'Extintor Vigente',
          'Botiquín',
          'Cinturones de Seguridad',
        ],
      };
    }

    // Inicializar respuestas en true (Apto) por defecto
    _checklistAnswers = {};
    _currentItems.forEach((_, items) {
      for (var item in items) {
        _checklistAnswers[item] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Checklist: ${widget.vehiculo.placa}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),

            _buildPhotoSection(),
            const SizedBox(height: 20),

            // Horómetro solo si NO es Aéreo (o si el usuario quiere registrarlo)
            // Usuario pidió: "tractores aereos seria verificar aceite y filtro ya que estos no tienen odometro"
            if (!_isAerial) ...[
              _buildHorometroField(),
              const SizedBox(height: 20),
            ],

            const Divider(color: Colors.white24),
            const SizedBox(height: 10),

            _buildChecklistItems(),

            const SizedBox(height: 20),
            TextFormField(
              controller: _observacionesController,
              decoration: const InputDecoration(
                labelText: 'Observaciones Generales',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAllOk() ? Colors.green : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isAllOk()
                            ? 'REGISTRAR (APROBADO)'
                            : 'REGISTRAR (CON FALLOS)',
                      ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EVIDENCIA FOTOGRÁFICA',
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _takePhoto,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _imageFile != null ? Colors.green : Colors.white24,
                width: 2,
              ),
            ),
            child: _imageFile != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(
                          _imageFile!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _takePhoto,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 40,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Capturar Evidencia',
                        style: GoogleFonts.oswald(color: Colors.white54),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              widget.vehiculo.tipo.toUpperCase(),
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${widget.vehiculo.marca} ${widget.vehiculo.modelo}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorometroField() {
    return TextFormField(
      controller: _horometroController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Horómetro / Kilometraje Actual',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.speed),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Requerido';
        if (double.tryParse(val) == null) return 'Inválido';
        return null;
      },
    );
  }

  Widget _buildChecklistItems() {
    return Column(
      children: _currentItems.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.key.toUpperCase(),
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...entry.value.map((item) => _buildCheckTile(item)),
            const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCheckTile(String item) {
    final bool isOk = _checklistAnswers[item] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOk
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.red.withValues(alpha: 0.1),
      child: SwitchListTile(
        title: Text(item, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          isOk ? 'OK / Buen Estado' : 'FALLO / Requiere Atención',
          style: TextStyle(color: isOk ? Colors.green : Colors.red),
        ),
        activeThumbColor: Colors.green,
        inactiveTrackColor: Colors.red.shade900,
        inactiveThumbColor: Colors.red,
        value: isOk,
        onChanged: (val) {
          setState(() {
            _checklistAnswers[item] = val;
          });
        },
      ),
    );
  }

  bool _isAllOk() {
    return !_checklistAnswers.containsValue(false);
  }

  void _submit() async {
    if (_isAerial) {
      // No validar form key para aéreos si no tienen horómetro
    } else {
      if (!_formKey.currentState!.validate()) return;
    }

    final provider = context.read<ChecklistProvider>();
    final isApto = _isAllOk();

    final checklist = ChecklistPreoperacional(
      id: 0,
      vehiculoId: widget.vehiculo.id,
      usuarioId: 0,
      fecha: DateTime.now(),
      horometroActual: _horometroController.text.isNotEmpty
          ? double.tryParse(_horometroController.text)
          : null,
      checklistData: _checklistAnswers,
      observaciones: _observacionesController.text,
      estado: isApto ? 'aprobado' : 'rechazado',
    );

    final success = await provider.registrarChecklist(
      checklist,
      localImagePath: _imageFile?.path,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checklist registrado correctamente')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${provider.error}')));
      }
    }
  }
}
