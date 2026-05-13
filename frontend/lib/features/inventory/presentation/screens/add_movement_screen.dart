import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
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
import 'package:frontend/core/database/database_helper.dart';
import 'package:frontend/core/widgets/semanur_autocomplete.dart';
import 'package:frontend/core/widgets/local_error_msg.dart';

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
  String _type = 'salida'; 
  String? _reason;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  OrdenTrabajo? _selectedOT;
  Vehiculo? _selectedVehicle;
  User? _selectedMechanic;
  String? _localError;

  List<Map<String, dynamic>> _bodegas = [];
  int? _selectedBodegaId;
  bool _isLoadingBodegas = true;

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
      _loadBodegas();
    });
  }

  Future<void> _loadBodegas() async {
    try {
      final bodegas = await DatabaseHelper().getBodegas();
      if (mounted) {
        setState(() {
          _bodegas = bodegas;
          _isLoadingBodegas = false;
          final standard = bodegas.firstWhere(
            (b) => b['tipo'] == 'estandar',
            orElse: () => bodegas.isNotEmpty ? bodegas.first : {},
          );
          if (standard.isNotEmpty) {
            _selectedBodegaId = standard['bodega_id'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading bodegas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = context.watch<InventoryProvider>();
    final workshopProvider = context.watch<WorkshopProvider>();
    final fleetProvider = context.watch<FleetProvider>();
    final userProvider = context.watch<UserProvider>();
    final movementProvider = context.watch<MovementProvider>();

    return SemanurScaffold(
      appBar: AppBar(title: const Text('Registrar Movimiento')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalErrorMsg(error: _localError, padding: EdgeInsets.zero),
                const SizedBox(height: 16),
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
                            ? null
                            : (val) => setState(() {
                                _type = 'salida';
                                _reason = null;
                              }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('INGRESO')),
                        selected: _type == 'ingreso',
                        selectedColor: Colors.green.shade100,
                        onSelected: widget.initialOT != null
                            ? null
                            : (val) => setState(() {
                                _type = 'ingreso';
                                _reason = null;
                              }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('TRASLADO')),
                        selected: _type == 'transferencia',
                        selectedColor: Colors.blue.shade100,
                        onSelected: widget.initialOT != null
                            ? null
                            : (val) => setState(() {
                                _type = 'transferencia';
                                _reason = 'Transferencia entre Bodegas';
                              }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('PRODUCTO *'),
                SemanurAutocomplete<Producto>(
                  options: inventoryProvider.productos,
                  initialValue: _selectedProduct,
                  hint: 'Seleccionar Producto...',
                  displayStringForOption: (p) =>
                      '${p.nombre} (${p.sku}) - Stock: ${p.stockActual}',
                  filterFn: (p, filter) =>
                      p.nombre.toLowerCase().contains(filter) ||
                      p.sku.toLowerCase().contains(filter),
                  onSelected: (p) => setState(() => _selectedProduct = p),
                ),
                const SizedBox(height: 24),

                if (_type != 'transferencia' &&
                    !_isLoadingBodegas &&
                    _bodegas.isNotEmpty) ...[
                  _buildSectionTitle('BODEGA *'),
                  DropdownButtonFormField<int>(
                    key: ValueKey(_selectedBodegaId),
                    initialValue: _selectedBodegaId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Seleccionar Bodega',
                    ),
                    items: _bodegas.map((b) {
                      return DropdownMenuItem<int>(
                        value: b['bodega_id'],
                        child: Text('${b['nombre']} (${b['tipo']})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBodegaId = val),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_type == 'transferencia') ...[
                  _buildSectionTitle('BODEGAS IMPLICADAS'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.outbound, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Origen: Bodega Principal (Estándar)'),
                          ],
                        ),
                        Divider(),
                        Row(
                          children: [
                            Icon(Icons.input, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Destino: Bodega Recuperación'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_type != 'transferencia') ...[
                  _buildSectionTitle('MOTIVO *'),
                  if (_type == 'salida')
                    SemanurAutocomplete<String>(
                      options: _exitReasons,
                      initialValue: _reason,
                      hint: 'Seleccionar motivo...',
                      displayStringForOption: (r) => r,
                      filterFn: (r, filter) => r.toLowerCase().contains(filter),
                      onSelected: (val) => setState(() {
                        _reason = val;
                        _selectedOT = null;
                        _selectedVehicle = null;
                        _selectedMechanic = null;
                      }),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _reason,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Seleccionar motivo',
                      ),
                      items: _entryReasons.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r));
                      }).toList(),
                      onChanged: (val) => setState(() => _reason = val),
                    ),
                  const SizedBox(height: 24),
                ],

                if (_reason == 'Salida por Orden de Trabajo') ...[
                  _buildSectionTitle('ORDEN DE TRABAJO *'),
                  SemanurAutocomplete<OrdenTrabajo>(
                    options: workshopProvider.ordenes,
                    initialValue: _selectedOT,
                    hint: 'Seleccionar OT...',
                    displayStringForOption: (ot) =>
                        'OT #${ot.id} - ${ot.vehiculo?.placa ?? 'S/P'}',
                    filterFn: (ot, filter) =>
                        ot.id.toString().contains(filter) ||
                        (ot.vehiculo?.placa.toLowerCase().contains(filter) ?? false),
                    onSelected: (ot) => setState(() => _selectedOT = ot),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_reason == 'Consumo de Combustible' ||
                    _reason == 'Entrega Directa sin OT') ...[
                  _buildSectionTitle('VEHÍCULO / MAQUINARIA *'),
                  SemanurAutocomplete<Vehiculo>(
                    options: fleetProvider.vehiculos,
                    initialValue: _selectedVehicle,
                    hint: 'Seleccionar vehículo...',
                    displayStringForOption: (v) => '${v.placa} - ${v.marca}',
                    filterFn: (v, filter) =>
                        v.placa.toLowerCase().contains(filter) ||
                        v.marca.toLowerCase().contains(filter),
                    onSelected: (v) => setState(() => _selectedVehicle = v),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_reason == 'Préstamo' || _reason == 'Entrega Directa sin OT') ...[
                  _buildSectionTitle('RESPONSABLE'),
                  SemanurAutocomplete<User>(
                    options: userProvider.users,
                    initialValue: _selectedMechanic,
                    hint: 'Seleccionar responsable...',
                    displayStringForOption: (u) => u.name,
                    filterFn: (u, filter) =>
                        u.name.toLowerCase().contains(filter),
                    onSelected: (u) => setState(() => _selectedMechanic = u),
                  ),
                  const SizedBox(height: 24),
                ],

                _buildSectionTitle('CANTIDAD *'),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '0.00',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  validator: (val) => (val == null || val.isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('NOTAS / OBSERVACIONES'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Opcional...',
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: movementProvider.isLoading ? null : () => _submit(context),
                    child: movementProvider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('REGISTRAR MOVIMIENTO'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _localError = 'Completa los campos obligatorios (*)');
      return;
    }

    if (_selectedProduct == null ||
        (_type != 'transferencia' && _selectedBodegaId == null)) {
      setState(() => _localError = 'Faltan datos obligatorios (Producto/Bodega)');
      return;
    }

    final qty = double.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0) {
      setState(() => _localError = 'Cantidad inválida');
      return;
    }

    if (_reason == null && _type != 'transferencia') {
      setState(() => _localError = 'Seleccione un motivo');
      return;
    }

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

    if (_type == 'transferencia') {
      final origen = _bodegas.firstWhere(
        (b) => b['tipo'] == 'estandar',
        orElse: () => {},
      );
      final destino = _bodegas.firstWhere(
        (b) => b['tipo'] == 'recuperacion',
        orElse: () => {},
      );

      if (origen.isEmpty || destino.isEmpty) {
        setState(() => _localError = 'Bodegas origen/destino no encontradas');
        return;
      }

      final success = await provider.registrarMovimiento(
        productoId: _selectedProduct!.id,
        tipo: 'transferencia',
        cantidad: qty,
        motivo: 'Transferencia a Recuperación',
        notas: finalNotes,
        bodegaOrigenId: origen['bodega_id'],
        bodegaDestinoId: destino['bodega_id'],
      );
      if (success) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Transferencia registrada correctamente')),
        );
        navigator.pop();
      } else {
        setState(() => _localError = provider.error);
      }
      return;
    }

    final success = await provider.registrarMovimiento(
      productoId: _selectedProduct!.id,
      tipo: _type,
      cantidad: qty,
      motivo: _reason!,
      referenciaId: refId,
      referenciaType: refType,
      notas: finalNotes,
      bodegaId: _selectedBodegaId,
    );

    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Movimiento registrado correctamente')),
      );
      navigator.pop();
    } else {
      setState(() => _localError = provider.error);
    }
  }
}
