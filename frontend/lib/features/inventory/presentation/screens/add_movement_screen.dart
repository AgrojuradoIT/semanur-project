import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/movement_provider.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/workshop/data/models/work_order_model.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddMovementScreen extends StatefulWidget {
  final OrdenTrabajo? initialOT;
  final Producto? initialProduct;

  const AddMovementScreen({super.key, this.initialOT, this.initialProduct});

  @override
  State<AddMovementScreen> createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  final _formKey = GlobalKey<FormState>();

  Producto? _selectedProduct;
  String _type = 'salida'; // Default to exit as it's more common
  String? _reason;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  OrdenTrabajo? _selectedOT;
  Vehiculo? _selectedVehicle;
  User? _selectedMechanic;

  final List<String> _entryReasons = [
    'Compra',
    'Devolución',
    'Ajuste Positivo',
  ];
  final List<String> _exitReasons = [
    'Salida por Orden de Trabajo',
    'Entrega Directa sin OT',
    'Préstamo',
    'Ajuste o Merma',
    'Consumo de Combustible',
  ];

  @override
  void initState() {
    super.initState();
    _selectedOT = widget.initialOT;
    _selectedProduct = widget.initialProduct;
    if (_selectedOT != null) {
      _type = 'salida';
      _reason = 'Salida por Orden de Trabajo';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos();
      context.read<WorkshopProvider>().fetchOrdenes();
      context.read<FleetProvider>().fetchVehiculos();
      context.read<UserProvider>().fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final workshopProvider = context.watch<WorkshopProvider>();
    final fleetProvider = context.watch<FleetProvider>();
    final userProvider = context.watch<UserProvider>();
    final movementProvider = context.watch<MovementProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipo de Movimiento
              const Text(
                'TIPO DE MOVIMIENTO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('SALIDA')),
                      selected: _type == 'salida',
                      selectedColor: Colors.red.shade100,
                      onSelected: widget.initialOT != null
                          ? null // Deshabilitar si está fijo
                          : (val) => setState(() {
                              _type = 'salida';
                              _reason = null;
                            }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('INGRESO')),
                      selected: _type == 'ingreso',
                      selectedColor: Colors.green.shade100,
                      // Si hay OT inicial, bloqueamos el ingreso (asumiendo que entregar repuesto siempre es salida)
                      onSelected: widget.initialOT != null
                          ? null
                          : (val) => setState(() {
                              _type = 'ingreso';
                              _reason = null;
                            }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('PRODUCTO'),
              DropdownSearch<Producto>(
                items: (filter, loadProps) => Future.value(
                  inventoryProvider.productos
                      .where(
                        (p) => p.nombre.toLowerCase().contains(
                          filter.toLowerCase(),
                        ),
                      )
                      .toList(),
                ),
                itemAsString: (Producto p) =>
                    '${p.nombre} (${p.sku}) - Stock: ${p.stockActual}',
                selectedItem: _selectedProduct,
                onChanged: (val) => setState(() => _selectedProduct = val),
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
                validator: (val) =>
                    val == null ? 'Seleccione un producto' : null,
              ),
              const SizedBox(height: 24),

              // Motivo
              _buildSectionTitle('MOTIVO'),
              DropdownButtonFormField<String>(
                // key removed to prevent rebuilds on change
                initialValue: _reason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Seleccionar motivo',
                ),
                items: (_type == 'ingreso' ? _entryReasons : _exitReasons).map((
                  r,
                ) {
                  return DropdownMenuItem(value: r, child: Text(r));
                }).toList(),
                onChanged: widget.initialOT != null
                    ? null
                    : (val) => setState(() {
                        _reason = val;
                        _selectedOT = null;
                        _selectedVehicle = null;
                        _selectedMechanic = null;
                      }),
                validator: (val) => val == null ? 'Seleccione un motivo' : null,
              ),
              const SizedBox(height: 24),

              // Campos Dinámicos
              if (_reason == 'Salida por Orden de Trabajo') ...[
                _buildSectionTitle('ORDEN DE TRABAJO'),
                DropdownSearch<OrdenTrabajo>(
                  items: (filter, loadProps) =>
                      Future.value(workshopProvider.ordenes),
                  itemAsString: (OrdenTrabajo ot) =>
                      'OT #${ot.id} - ${ot.vehiculo?.placa ?? 'Sin Placa'}',
                  selectedItem: _selectedOT,
                  enabled: widget.initialOT == null, // Bloquear si viene fijo
                  onChanged: (val) => setState(() => _selectedOT = val),
                  compareFn: (item, sItem) => item.id == sItem.id,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Buscar OT...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  validator: (val) =>
                      val == null ? 'Vincule una orden de trabajo' : null,
                ),
                const SizedBox(height: 24),
              ],

              if (_reason == 'Entrega Directa sin OT' ||
                  _reason == 'Consumo de Combustible') ...[
                _buildSectionTitle('VEHÍCULO DESTINO'),
                DropdownSearch<Vehiculo>(
                  items: (filter, loadProps) => Future.value(
                    fleetProvider.vehiculos
                        .where(
                          (v) => v.placa.toLowerCase().contains(
                            filter.toLowerCase(),
                          ),
                        )
                        .toList(),
                  ),
                  itemAsString: (Vehiculo v) =>
                      '${v.placa} - ${v.marca} ${v.modelo}',
                  selectedItem: _selectedVehicle,
                  onChanged: (val) => setState(() => _selectedVehicle = val),
                  compareFn: (item, sItem) => item.id == sItem.id,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Buscar placa...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  validator: (val) =>
                      val == null ? 'Seleccione un vehículo' : null,
                ),
                const SizedBox(height: 24),
              ],

              if (_reason == 'Entrega Directa sin OT' ||
                  _reason == 'Préstamo') ...[
                _buildSectionTitle('MECÁNICO RESPONSABLE'),
                DropdownSearch<User>(
                  items: (filter, loadProps) => Future.value(
                    userProvider.users
                        .where(
                          (u) => u.name.toLowerCase().contains(
                            filter.toLowerCase(),
                          ),
                        )
                        .toList(),
                  ),
                  itemAsString: (User u) => u.name,
                  selectedItem: _selectedMechanic,
                  onChanged: (val) => setState(() => _selectedMechanic = val),
                  compareFn: (item, sItem) => item.id == sItem.id,
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: "Buscar nombre...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  validator: (val) =>
                      val == null ? 'Seleccione un responsable' : null,
                ),
                const SizedBox(height: 24),
              ],

              // Cantidad
              _buildSectionTitle('CANTIDAD'),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Ingrese cantidad';
                  final n = double.tryParse(val);
                  if (n == null || n <= 0) return 'Ingrese un número válido';
                  if (_type == 'salida' &&
                      _selectedProduct != null &&
                      n > _selectedProduct!.stockActual) {
                    return 'Stock insuficiente (Max: ${_selectedProduct!.stockActual})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Notas
              _buildSectionTitle('NOTAS / OBSERVACIONES'),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 40),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: movementProvider.isLoading
                      ? null
                      : () => _submit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'ingreso'
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: movementProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('REGISTRAR ${_type.toUpperCase()}'),
                ),
              ),
              const SizedBox(height: 100), // Espacio extra para scroll
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  void _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MovementProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    int? refId;
    String? refType;

    if (_reason == 'Salida por Orden de Trabajo') {
      refId = _selectedOT?.id;
      refType = 'OrdenTrabajo';
    } else if (_reason == 'Entrega Directa sin OT' ||
        _reason == 'Consumo de Combustible') {
      refId = _selectedVehicle?.id;
      refType = 'Vehiculo';
    } else if (_reason == 'Préstamo') {
      refId = _selectedMechanic?.id;
      refType = 'User';
    }

    String finalNotes = _notesController.text;
    if (_reason == 'Entrega Directa sin OT' && _selectedMechanic != null) {
      finalNotes += '\nResponsable: ${_selectedMechanic!.name}';
    }

    final success = await provider.registrarMovimiento(
      productoId: _selectedProduct!.id,
      tipo: _type,
      cantidad: double.parse(_quantityController.text),
      motivo: _reason!,
      referenciaId: refId,
      referenciaType: refType,
      notas: finalNotes,
    );

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Movimiento registrado correctamente')),
      );
      navigator.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
