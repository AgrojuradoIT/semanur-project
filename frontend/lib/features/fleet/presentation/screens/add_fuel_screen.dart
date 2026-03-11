import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:frontend/features/auth/presentation/providers/employee_provider.dart';
import 'package:frontend/features/auth/data/models/empleado_model.dart';
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
  final _horometroController = TextEditingController();
  final _kilometrajeController = TextEditingController();
  final _notasController = TextEditingController();
  final _terceroController = TextEditingController();
  final _placaManualController = TextEditingController();
  final _laborController = TextEditingController();

  String _tipoCombustible = 'gasolina';

  // Destination State
  String _tipoDestino = 'vehiculo'; // vehiculo, empleado, tercero
  Vehiculo? _selectedVehicle;
  Empleado? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos();
      context.read<FleetProvider>().fetchVehiculos();
      context.read<EmployeeProvider>().loadEmployees();

      // Default internal text if left empty during submission

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
                value: _tipoDestino,
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
                    value: _selectedVehicle,
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

            if (_tipoDestino == 'vehiculo') ...[
              const SizedBox(height: 10),
              Consumer<EmployeeProvider>(
                builder: (context, employeeProvider, _) {
                  return DropdownButtonFormField<Empleado>(
                    value: _selectedEmployee,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'A quién se le entrega (Empleado)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: employeeProvider.employees.map((e) {
                      return DropdownMenuItem(value: e, child: Text(e.nombreCompleto));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedEmployee = val),
                    validator: (val) =>
                        _tipoDestino == 'vehiculo' && val == null
                        ? 'Seleccione un empleado'
                        : null,
                  );
                },
              ),
            ],

            if (_tipoDestino == 'empleado') ...[
              TextFormField(
                controller: _terceroController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Empleado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) =>
                    _tipoDestino == 'empleado' && (val == null || val.isEmpty)
                    ? 'Ingrese el nombre del empleado'
                    : null,
              ),
              const SizedBox(height: 10),
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
              'DATOS DE ABASTECIMIENTO (Interno)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Tipo de Combustible
            DropdownButtonFormField<String>(
              value: _tipoCombustible,
              decoration: const InputDecoration(
                labelText: 'Tipo de Combustible',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_gas_station),
              ),
              items: const [
                DropdownMenuItem(value: 'gasolina', child: Text('Gasolina')),
                DropdownMenuItem(value: 'acpm', child: Text('ACPM')),
              ],
              onChanged: (val) => setState(() => _tipoCombustible = val!),
            ),
            const SizedBox(height: 20),

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
                return null;
              },
            ),
            const SizedBox(height: 20),

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

            TextFormField(
              controller: _laborController,
              decoration: const InputDecoration(
                labelText: 'Destino o Labor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
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
      int? vehiculoId = widget.vehiculoId ?? _selectedVehicle?.id;
      int? empleadoId = _tipoDestino == 'vehiculo'
          ? _selectedEmployee?.id
          : null;
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
            : null,
        tipoDestino: _tipoDestino,
        cantidad: double.parse(_cantidadController.text),
        valor: 0,
        horometro: _horometroController.text.isNotEmpty
            ? double.parse(_horometroController.text)
            : null,
        kilometraje: _kilometrajeController.text.isNotEmpty
            ? double.parse(_kilometrajeController.text)
            : null,
        notas: _notasController.text,
        labor: _laborController.text.isNotEmpty ? _laborController.text : null,
        productoId: null, // Asignado en backend
        tipoCombustible: _tipoCombustible,
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
