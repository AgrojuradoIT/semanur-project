import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import 'package:frontend/features/auth/presentation/providers/user_provider.dart';
import '../providers/fuel_provider.dart';

class AddFuelScreen extends StatefulWidget {
  final int? vehiculoId;
  final String? placa;

  const AddFuelScreen({super.key, this.vehiculoId, this.placa});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _valorController = TextEditingController();
  final _horometroController = TextEditingController();
  final _kilometrajeController = TextEditingController();
  final _estacionController = TextEditingController();
  final _notasController = TextEditingController();
  final _terceroController = TextEditingController();
  final _placaManualController = TextEditingController();

  bool _isInternal = true;
  Producto? _selectedProduct;

  // Destination State
  String _tipoDestino = 'vehiculo'; // vehiculo, empleado, tercero
  Vehiculo? _selectedVehicle;
  User? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos();
      context.read<FleetProvider>().fetchVehiculos();
      context.read<UserProvider>().fetchUsers();

      // Initialize text for internal mode
      if (_isInternal) {
        _estacionController.text = 'Inventario Interno';
      }

      // Pre-select vehicle if provided
      if (widget.vehiculoId != null) {
        setState(() {
          _tipoDestino = 'vehiculo';
          // We don't have the full vehicle object easily here unless we fetch it or find it in provider
          // But we can just use the ID for submission.
          // However, for consistency, if we are in 'vehiculo' mode, we might want to select it in dropdown if we show it.
          // Since we might want to hide the selection if context is fixed:
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If widget.vehiculoId is provided, we lock the destination to that vehicle.
    final bool isContextFixed = widget.vehiculoId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isContextFixed
              ? 'Tanqueo: ${widget.placa}'
              : 'Registrar Abastecimiento',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Destination Selection (Only if not fixed context)
            if (!isContextFixed) ...[
              const Text(
                'DESTINATARIO',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _tipoDestino,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Destino',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'vehiculo', child: Text('Vehículo')),
                  DropdownMenuItem(
                    value: 'empleado',
                    child: Text('Empleado / Operario'),
                  ),
                  DropdownMenuItem(
                    value: 'tercero',
                    child: Text('Tercero / Otro'),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _tipoDestino = val!;
                    // Clear selections when changing type
                    _selectedVehicle = null;
                    _selectedEmployee = null;
                    _terceroController.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
            ],

            // Dynamic Fields based on Destination
            if (_tipoDestino == 'vehiculo' && !isContextFixed)
              Consumer<FleetProvider>(
                builder: (context, fleet, _) {
                  return DropdownButtonFormField<Vehiculo>(
                    initialValue: _selectedVehicle,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Vehículo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.directions_car),
                    ),
                    items: fleet.vehiculos.map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text('${v.placa} - ${v.marca} ${v.modelo}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedVehicle = val),
                    validator: (val) =>
                        _tipoDestino == 'vehiculo' && val == null
                        ? 'Seleccione un vehículo'
                        : null,
                  );
                },
              ),

            if (_tipoDestino == 'empleado') ...[
              Consumer<UserProvider>(
                builder: (context, users, _) {
                  return DropdownButtonFormField<User>(
                    initialValue: _selectedEmployee,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Empleado',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: users.users.map((u) {
                      return DropdownMenuItem(value: u, child: Text(u.name));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedEmployee = val),
                    validator: (val) =>
                        _tipoDestino == 'empleado' && val == null
                        ? 'Seleccione un empleado'
                        : null,
                  );
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller:
                    _terceroController, // Reusamos este para la placa manual en empleado opcional
                decoration: const InputDecoration(
                  labelText: 'Placa del Vehículo (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
            ],

            if (_tipoDestino == 'tercero') ...[
              TextFormField(
                controller: _terceroController, // Nombre del tercero
                decoration: const InputDecoration(
                  labelText: 'Nombre del Tercero',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) =>
                    _tipoDestino == 'tercero' && (val == null || val.isEmpty)
                    ? 'Ingrese el nombre'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller:
                    _placaManualController, // Nuevo controlador para placa
                decoration: const InputDecoration(
                  labelText: 'Placa del Vehículo (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car_outlined),
                ),
              ),
            ],

            const SizedBox(height: 30),

            const Text(
              'DATOS DE ABASTECIMIENTO',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            // Switch Origen
            SwitchListTile(
              title: const Text('Origen: Inventario Interno'),
              subtitle: Text(
                _isInternal
                    ? 'Descontar del Inventario'
                    : 'Estación de Servicio Externa',
              ),
              value: _isInternal,
              onChanged: (val) {
                setState(() {
                  _isInternal = val;
                  if (_isInternal) {
                    _estacionController.text = 'Inventario Interno';
                  } else {
                    _estacionController.clear();
                    _selectedProduct = null;
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            if (_isInternal)
              Consumer<InventoryProvider>(
                builder: (context, invProvider, child) {
                  final combustibles = invProvider.productos
                      .where(
                        (p) =>
                            p.categoria?.tipo?.toLowerCase() == 'combustible',
                      )
                      .toList();

                  return DropdownButtonFormField<Producto>(
                    key: ValueKey(_selectedProduct?.id),
                    isExpanded: true,
                    initialValue: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Producto (Combustible)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory),
                    ),
                    items: combustibles.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.nombre} (Stock: ${p.stockActual})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedProduct = val),
                    validator: (val) => _isInternal && val == null
                        ? 'Seleccione producto'
                        : null,
                  );
                },
              ),
            if (_isInternal) const SizedBox(height: 20),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad (Galones)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Ingrese galones';
                if (_isInternal && _selectedProduct != null) {
                  final qty = double.tryParse(val);
                  if (qty != null && qty > _selectedProduct!.stockActual) {
                    return 'Stock insuficiente (Max: ${_selectedProduct!.stockActual})';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            if (!_isInternal) ...[
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor Total (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                ),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    (!_isInternal && (val == null || val.isEmpty))
                    ? 'Ingrese valor total'
                    : null,
              ),
              const SizedBox(height: 20),
            ],

            // Checking (Horometer/Odometer) only if destination is Vehicle
            if (_tipoDestino == 'vehiculo') ...[
              const Text(
                'SEGUIMIENTO (OPCIONAL)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _horometroController,
                      decoration: const InputDecoration(
                        labelText: 'Horómetro',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _kilometrajeController,
                      decoration: const InputDecoration(
                        labelText: 'Kilometraje',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.speed),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            if (!_isInternal)
              TextFormField(
                controller: _estacionController,
                decoration: const InputDecoration(
                  labelText: 'Estación de Servicio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: 'Notas / Observaciones',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),
            Consumer<FuelProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'REGISTRAR TANQUEO',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Determine IDs based on type
      int? vehiculoId = widget.vehiculoId ?? _selectedVehicle?.id;
      int? empleadoId = _selectedEmployee?.id;
      String? terceroNombre = _terceroController.text.isNotEmpty
          ? _terceroController.text
          : null;

      if (_tipoDestino == 'vehiculo' && vehiculoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Vehículo no seleccionado')),
        );
        return;
      }

      final success = await context.read<FuelProvider>().registrarTanqueo(
        vehiculoId: vehiculoId,
        empleadoId: empleadoId,
        terceroNombre: terceroNombre,
        placaManual: _placaManualController.text.isNotEmpty
            ? _placaManualController.text
            : (_tipoDestino == 'empleado' && _terceroController.text.isNotEmpty
                  ? _terceroController.text
                  : null),
        tipoDestino: _tipoDestino,
        cantidad: double.parse(_cantidadController.text),
        valor: _isInternal ? 0.0 : double.parse(_valorController.text),
        horometro: _horometroController.text.isNotEmpty
            ? double.parse(_horometroController.text)
            : null,
        kilometraje: _kilometrajeController.text.isNotEmpty
            ? double.parse(_kilometrajeController.text)
            : null,
        estacion: _isInternal ? 'Inventario Interno' : _estacionController.text,
        notas: _notasController.text,
        productoId: _isInternal ? _selectedProduct?.id : null,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro guardado correctamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${context.read<FuelProvider>().error}'),
            ),
          );
        }
      }
    }
  }
}
