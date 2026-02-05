import 'package:flutter/material.dart';
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

  final List<String> _priorities = ['Baja', 'Media', 'Alta'];

  // Listas de items seleccionados
  final List<Map<String, dynamic>> _selectedSpares = [];
  final List<Map<String, dynamic>> _selectedTools = [];

  // Controllers para dropdowns temporales
  Producto? _tempSpare;
  Producto? _tempTool;
  final _spareQtyController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchVehiculos();
      context.read<InventoryProvider>().fetchProductos();
    });
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

  @override
  Widget build(BuildContext context) {
    final fleetProvider = context.watch<FleetProvider>();
    final workshopProvider = context.watch<WorkshopProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          'NUEVA ORDEN DE TRABAJO',
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
              _buildSectionTitle('VEHÍCULO / MAQUINARIA'),
              _buildVehicleDropdown(fleetProvider),
              const SizedBox(height: 25),

              _buildSectionTitle('PRIORIDAD DE LA ORDEN'),
              _buildPrioritySelector(),
              const SizedBox(height: 25),

              _buildSectionTitle('DESCRIPCIÓN DEL TRABAJO / FALLA'),
              _buildDescriptionField(),
              const SizedBox(height: 25),

              _buildSectionTitle('EVIDENCIA FOTOGRÁFICA'),
              _buildPhotoSection(),
              const SizedBox(height: 25),

              _buildSectionTitle('REPUESTOS REQUERIDOS (OPCIONAL)'),
              _buildSparesSelector(context),
              _buildSparesList(),
              const SizedBox(height: 25),

              _buildSectionTitle('HERRAMIENTAS A UTILIZAR (OPCIONAL)'),
              _buildToolsSelector(context),
              _buildToolsList(),
              const SizedBox(height: 40),

              _buildSubmitButton(workshopProvider),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: _imageFile != null ? Colors.green : AppTheme.surfaceDark2,
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
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CAPTURAR EVIDENCIA',
                    style: GoogleFonts.oswald(
                      color: Colors.white38,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.oswald(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryYellow,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildVehicleDropdown(FleetProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: DropdownButtonFormField<Vehiculo>(
        initialValue: _selectedVehicle,
        dropdownColor: AppTheme.surfaceDark,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          border: InputBorder.none,
          hintText: 'Seleccionar vehículo...',
          hintStyle: TextStyle(color: AppTheme.textGray, fontSize: 14),
        ),
        items: provider.vehiculos.map((v) {
          return DropdownMenuItem(
            value: v,
            child: Text(
              '${v.placa} - ${v.marca} ${v.modelo}',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (val) => setState(() => _selectedVehicle = val),
        validator: (val) =>
            val == null ? 'Por favor seleccione un vehículo' : null,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: _priorities.map((p) {
        final isSelected = _priority == p;
        Color priorityColor = Colors.grey;
        if (p == 'Alta') priorityColor = Colors.red;
        if (p == 'Media') priorityColor = AppTheme.primaryYellow;
        if (p == 'Baja') priorityColor = Colors.green;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              margin: EdgeInsets.only(right: p != _priorities.last ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? priorityColor.withValues(alpha: 0.2)
                    : AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? priorityColor : AppTheme.surfaceDark2,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  p.toUpperCase(),
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? priorityColor : Colors.white60,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 5,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(20),
          border: InputBorder.none,
          hintText:
              'Especifique el motivo de la orden, fallas detectadas o mantenimiento requerido...',
          hintStyle: TextStyle(color: AppTheme.textGray, fontSize: 13),
        ),
        validator: (val) => val == null || val.isEmpty
            ? 'Por favor ingrese una descripción'
            : null,
      ),
    );
  }

  Widget _buildSubmitButton(WorkshopProvider provider) {
    return SizedBox(
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
                'CREAR ORDEN DE TRABAJO',
                style: GoogleFonts.oswald(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  Widget _buildSparesSelector(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final spares = inventoryProvider.productos
        .where((p) => (p.categoria?.tipo?.toLowerCase() ?? '') == 'repuesto')
        .toList();

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'REPUESTO A SOLICITAR',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Usando async implementation para compatibilidad
              // Usando sintaxis compatible con v5/Legacy
              DropdownSearch<Producto>(
                key: ValueKey('spare_${_tempSpare?.id}'),
                items: (filter, loadProps) => Future.value(
                  spares
                      .where(
                        (element) => element.nombre.toLowerCase().contains(
                          filter.toLowerCase(),
                        ),
                      )
                      .toList(),
                ),
                itemAsString: (Producto p) => '${p.nombre} (${p.sku})',
                selectedItem: _tempSpare,
                onChanged: (val) => setState(() => _tempSpare = val),
                compareFn: (item, sItem) => item.id == sItem.id,
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Buscar por nombre o SKU...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: TextFormField(
            controller: _spareQtyController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cant.',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: _addSpare,
          tooltip: 'Agregar Repuesto',
        ),
      ],
    );
  }

  void _addSpare() {
    if (_tempSpare == null) return;
    final qty = double.tryParse(_spareQtyController.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cantidad inválida')));
      return;
    }
    if (qty > _tempSpare!.stockActual) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stock insuficiente')));
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

  Widget _buildSparesList() {
    if (_selectedSpares.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _selectedSpares.map((item) {
        return ListTile(
          dense: true,
          title: Text(
            '${item['sku']} - ${item['nombre']}',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            'Cantidad: ${item['cantidad']}',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              setState(() {
                _selectedSpares.remove(item);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildToolsSelector(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final tools = inventoryProvider.productos
        .where((p) => (p.categoria?.tipo?.toLowerCase() ?? '') == 'herramienta')
        .toList();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'HERRAMIENTA A SOLICITAR',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textGray,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownSearch<Producto>(
                key: ValueKey('tool_${_tempTool?.id}'),
                items: (filter, loadProps) => Future.value(
                  tools
                      .where(
                        (element) => element.nombre.toLowerCase().contains(
                          filter.toLowerCase(),
                        ),
                      )
                      .toList(),
                ),
                itemAsString: (Producto p) => '${p.nombre} (${p.sku})',
                selectedItem: _tempTool,
                onChanged: (val) => setState(() => _tempTool = val),
                compareFn: (item, sItem) => item.id == sItem.id,
                popupProps: const PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "Buscar por nombre o SKU...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.blue),
          onPressed: _addTool,
          tooltip: 'Agregar Herramienta',
        ),
      ],
    );
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

  Widget _buildToolsList() {
    if (_selectedTools.isEmpty) return const SizedBox.shrink();
    return Column(
      children: _selectedTools.map((item) {
        return ListTile(
          dense: true,
          title: Text(
            '${item['sku']} - ${item['nombre']}',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () {
              setState(() {
                _selectedTools.remove(item);
              });
            },
          ),
        );
      }).toList(),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await provider.crearOrden(
      vehiculoId: _selectedVehicle!.id,
      prioridad: _priority,
      descripcion: _descriptionController.text,
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
