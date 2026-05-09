import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:frontend/features/auth/presentation/providers/employee_provider.dart';

class AddWorkOrderScreen extends StatefulWidget {
  const AddWorkOrderScreen({super.key});

  @override
  State<AddWorkOrderScreen> createState() => _AddWorkOrderScreenState();
}

class _AddWorkOrderScreenState extends State<AddWorkOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  Vehiculo? _selectedVehicle;
  String _priority = 'Media';
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  Empleado? _selectedMechanic;

  final List<String> _priorities = ['Baja', 'Media', 'Alta'];
  final List<Map<String, dynamic>> _selectedSpares = [];
  final List<Map<String, dynamic>> _selectedTools = [];

  Producto? _tempSpare;
  Producto? _tempTool;
  final _spareQtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Solo fetch si no hay datos cargados
      final fleetProvider = context.read<FleetProvider>();
      final inventoryProvider = context.read<InventoryProvider>();
      final employeeProvider = context.read<EmployeeProvider>();
      
      if (fleetProvider.vehiculos.isEmpty) {
        fleetProvider.fetchVehiculos();
      }
      if (inventoryProvider.productos.isEmpty) {
        inventoryProvider.fetchProductos();
      }
      if (employeeProvider.employees.isEmpty) {
        employeeProvider.loadEmployees();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _spareQtyController.dispose();
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return const Color(0xFFFF4B2B);
      case 'media':
        return const Color(0xFFFFD600);
      case 'baja':
        return const Color(0xFF00E676);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fleetProvider = context.watch<FleetProvider>();
    final workshopProvider = context.watch<WorkshopProvider>();
    final employeeProvider = context.watch<EmployeeProvider>();

    return SemanurScaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leadingWidth: 60,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'NUEVA ORDEN',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildVehicleSection(fleetProvider),
            const SizedBox(height: 16),
            _buildPrioritySection(),
            const SizedBox(height: 16),
            _buildMechanicSection(employeeProvider),
            const SizedBox(height: 16),
            _buildDescriptionSection(),
            const SizedBox(height: 16),
            _buildEvidenceSection(),
            const SizedBox(height: 16),
            _buildSparesSection(),
            const SizedBox(height: 16),
            _buildToolsSection(),
            const SizedBox(height: 24),
            _buildSubmitButton(workshopProvider),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection(FleetProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'VEHÍCULO / MAQUINARIA',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Vehiculo>(
            value: _selectedVehicle,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Seleccione Vehículo...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF333333)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryYellow),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: provider.vehiculos.map((v) {
              return DropdownMenuItem(
                value: v,
                child: Text(
                  '${v.placa} - ${v.marca} ${v.modelo}',
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedVehicle = val),
            validator: (val) => val == null ? 'Seleccione un vehículo' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.warning_outlined,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NIVEL DE PRIORIDAD',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _priorities.map((priority) {
              final isSelected = _priority == priority;
              final color = _getPriorityColor(priority);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _priority = priority),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: priority != _priorities.last ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFF333333),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          priority.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : Colors.grey.shade500,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMechanicSection(EmployeeProvider provider) {
    final mechanics = provider.employees
        .where((e) => e.cargo?.toLowerCase().contains('mecanico') ?? false)
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ASIGNAR MECÁNICO',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Empleado>(
            value: _selectedMechanic,
            dropdownColor: const Color(0xFF1E1E1E),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Seleccione responsable...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF333333)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryYellow),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: mechanics.map((e) {
              return DropdownMenuItem(
                value: e,
                child: Text(e.nombreCompleto, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedMechanic = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.notes_outlined,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DESCRIPCIÓN DE FALLA',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Describa detalladamente el problema...',
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF333333)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF333333)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryYellow),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EVIDENCIA FOTOGRÁFICA',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _imageFile != null 
                          ? AppTheme.primaryYellow 
                          : const Color(0xFF333333),
                      width: 2,
                      style: _imageFile != null ? BorderStyle.solid : BorderStyle.none,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF121212),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.grey.shade600,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'CÁMARA',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              if (_imageFile != null) ...[
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _imageFile = null),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            opacity: const AlwaysStoppedAnimation(0.5),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparesSection() {
    final inventoryProvider = context.watch<InventoryProvider>();
    final spares = inventoryProvider.productos
        .where((p) => (p.categoria?.tipo?.toLowerCase() ?? '') == 'repuesto')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.build_outlined,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SOLICITUD DE REPUESTOS',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownSearch<Producto>(
                  selectedItem: _tempSpare,
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      hintText: 'Buscar SKU...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFF333333)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFF333333)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryYellow),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF121212),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    menuProps: MenuProps(
                      backgroundColor: const Color(0xFF1E1E1E),
                    ),
                  ),
                  items: (filter, loadProps) => Future.value(
                    spares.where((e) => 
                      e.nombre.toLowerCase().contains(filter.toLowerCase()) ||
                      e.sku.toLowerCase().contains(filter.toLowerCase())
                    ).toList(),
                  ),
                  itemAsString: (p) => '${p.sku} - ${p.nombre}',
                  onChanged: (val) => setState(() => _tempSpare = val),
                  compareFn: (item, sItem) => item.id == sItem.id,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _spareQtyController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Cant.',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF121212),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color(0xFF333333)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: const Color(0xFF333333)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppTheme.primaryYellow),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addSpare,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AGREGAR',
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedSpares.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedSpares.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _selectedSpares[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nombre'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['cantidad']} Unidades - ${item['sku']}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedSpares.removeAt(index));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolsSection() {
    final inventoryProvider = context.watch<InventoryProvider>();
    final tools = inventoryProvider.productos
        .where((p) => (p.categoria?.tipo?.toLowerCase() ?? '') == 'herramienta')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: AppTheme.primaryYellow,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRÉSTAMO DE HERRAMIENTAS',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade300,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownSearch<Producto>(
                  selectedItem: _tempTool,
                  decoratorProps: DropDownDecoratorProps(
                    decoration: InputDecoration(
                      hintText: 'Seleccione herramienta...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      filled: true,
                      fillColor: const Color(0xFF121212),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFF333333)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: const Color(0xFF333333)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryYellow),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'Buscar...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: const Color(0xFF121212),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    menuProps: MenuProps(
                      backgroundColor: const Color(0xFF1E1E1E),
                    ),
                  ),
                  items: (filter, loadProps) => Future.value(
                    tools.where((e) => 
                      e.nombre.toLowerCase().contains(filter.toLowerCase())
                    ).toList(),
                  ),
                  itemAsString: (p) => '${p.sku} - ${p.nombre}',
                  onChanged: (val) => setState(() => _tempTool = val),
                  compareFn: (item, sItem) => item.id == sItem.id,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addTool,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'AGREGAR',
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_selectedTools.isNotEmpty) ...[
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _selectedTools.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _selectedTools[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['nombre'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedTools.removeAt(index));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton(WorkshopProvider provider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryYellow.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: provider.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryYellow,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: provider.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'CREAR ORDEN',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
      ),
    );
  }

  void _addSpare() {
    if (_tempSpare == null) return;
    final qty = double.tryParse(_spareQtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }
    if (qty > _tempSpare!.stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente: ${_tempSpare!.stockActual}')),
      );
      return;
    }

    setState(() {
      _selectedSpares.add({
        'producto_id': _tempSpare!.id,
        'cantidad': qty,
        'nombre': _tempSpare!.nombre,
        'sku': _tempSpare!.sku,
      });
      _tempSpare = null;
      _spareQtyController.text = '1';
    });
  }

  void _addTool() {
    if (_tempTool == null) return;

    if (_selectedTools.any((t) => t['producto_id'] == _tempTool!.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta herramienta ya está en la lista')),
      );
      return;
    }

    setState(() {
      _selectedTools.add({
        'producto_id': _tempTool!.id,
        'nombre': _tempTool!.nombre,
        'sku': _tempTool!.sku,
      });
      _tempTool = null;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validar que haya vehículo seleccionado
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un vehículo')),
      );
      return;
    }

    final provider = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await provider.crearOrden(
      vehiculoId: _selectedVehicle!.id,
      prioridad: _priority,
      descripcion: _descriptionController.text,
      mecanicoId: _selectedMechanic?.id,
      repuestos: _selectedSpares,
      herramientas: _selectedTools,
      localImagePath: _imageFile?.path,
    );

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'ORDEN #${_selectedVehicle?.placa} CREADA EXITOSAMENTE',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('ERROR: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
