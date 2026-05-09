import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/core/utils/fuel_utils.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
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
  final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*([.,]\d{0,2})?$'),
  );

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

    return SemanurScaffold(
      currentNav: SemanurNavItem.fuel,
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

            if (_tipoDestino == 'vehiculo') ...[
              const SizedBox(height: 10),
              Consumer<EmployeeProvider>(
                builder: (context, employeeProvider, _) {
                  return DropdownButtonFormField<Empleado>(
                    initialValue: _selectedEmployee,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'A quién se le entrega (Empleado)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: employeeProvider.employees.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e.nombreCompleto),
                      );
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
              initialValue: _tipoCombustible,
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
            const SizedBox(height: 10),
            Consumer<InventoryProvider>(
              builder: (context, inventory, _) {
                final producto = _findFuelProduct(
                  inventory.productos,
                  _tipoCombustible,
                );
                if (producto == null) {
                  return const SizedBox.shrink();
                }

                final bool lowStock =
                    producto.stockActual <= producto.alertaStockMinimo;
                final Color statusColor = lowStock
                    ? Colors.redAccent
                    : Colors.green;
                final String unidad = producto.unidadMedida ?? 'GAL';

                final double capacidad = producto.capacidadMaxima ?? 0;
                final double ratio = capacidad > 0
                    ? (producto.stockActual / capacidad).clamp(0, 1)
                    : (producto.stockActual /
                            (producto.stockActual +
                                (producto.alertaStockMinimo > 0
                                    ? producto.alertaStockMinimo
                                    : 1)))
                        .clamp(0, 1);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.inventory_2, color: statusColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lowStock ? 'Stock bajo' : 'Stock disponible',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${producto.stockActual.toStringAsFixed(1)} $unidad',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: Colors.black12,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      if (capacidad > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Capacidad: ${capacidad.toStringAsFixed(1)} $unidad',
                          style: TextStyle(
                            color: statusColor.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
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
              inputFormatters: [_decimalFormatter],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Ingrese galones';
                final parsed = _parseDouble(val);
                if (parsed == null || parsed <= 0) {
                  return 'Cantidad inválida';
                }
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
                      inputFormatters: [_decimalFormatter],
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
                      inputFormatters: [_decimalFormatter],
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

  double? _parseDouble(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  Producto? _findFuelProduct(List<Producto> productos, String tipo) {
    final fuels = resolveFuelProducts(productos);
    if (tipo.toLowerCase() == 'gasolina') {
      return fuels.gasolina;
    }
    return fuels.acpm;
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      int? vehiculoId = widget.vehiculoId ?? _selectedVehicle?.id;
      int? empleadoId = _tipoDestino == 'vehiculo'
          ? _selectedEmployee?.id
          : null;
      String? terceroNombre = _terceroController.text.isNotEmpty
          ? _terceroController.text
          : null;
      final inventoryProvider = context.read<InventoryProvider>();
      final cantidad = _parseDouble(_cantidadController.text);

      if (_tipoDestino == 'vehiculo' && vehiculoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Vehículo no seleccionado')),
        );
        return;
      }

      if (cantidad == null || cantidad <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cantidad inválida')),
        );
        return;
      }

      final producto = _findFuelProduct(
        inventoryProvider.productos,
        _tipoCombustible,
      );
      if (producto != null && cantidad > producto.stockActual) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay stock suficiente. Disponible: ${producto.stockActual.toStringAsFixed(1)} ${producto.unidadMedida ?? 'GAL'}',
            ),
          ),
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
        cantidad: cantidad,
        valor: 0,
        horometro: _parseDouble(_horometroController.text),
        kilometraje: _parseDouble(_kilometrajeController.text),
        notas: _notasController.text,
        labor: _laborController.text.isNotEmpty ? _laborController.text : null,
        productoId: null, // Asignado en backend
        tipoCombustible: _tipoCombustible,
      );

      if (mounted) {
        if (success) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registro guardado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Limpiar formulario para nuevo registro
          _cantidadController.clear();
          _horometroController.clear();
          _kilometrajeController.clear();
          _notasController.clear();
          _terceroController.clear();
          _placaManualController.clear();
          _laborController.clear();
          
          // Resetear focus
          FocusScope.of(context).unfocus();
          
          // Refrescar el inventario para actualizar el stock mostrado
          if (mounted) {
            context.read<InventoryProvider>().fetchProductos(lowStock: false);
          }
          
          // NO cerrar la pantalla - permitir nuevo registro
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${context.read<FuelProvider>().error}'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }
}
