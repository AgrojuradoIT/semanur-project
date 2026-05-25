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
import 'package:frontend/core/widgets/semanur_autocomplete.dart';
import 'package:frontend/core/widgets/local_error_msg.dart';
import 'package:frontend/core/utils/vehicle_utils.dart';

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
  String? _localError;

  final _decimalFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*([.,]\d{0,2})?$'),
  );

  String _tipoDestino = 'vehiculo'; 
  Vehiculo? _selectedVehicle;
  Empleado? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos();
      context.read<FleetProvider>().fetchVehiculos();
      context.read<EmployeeProvider>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              LocalErrorMsg(error: _localError, padding: EdgeInsets.zero),
              const SizedBox(height: 16),
              
              if (!isContextFixed) ...[
                _buildSectionTitle('DESTINATARIO'),
                DropdownButtonFormField<String>(
                  initialValue: _tipoDestino,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Destino',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'vehiculo', child: Text('Vehículo')),
                    DropdownMenuItem(value: 'maquinaria', child: Text('Maquinaria Pesada')),
                    DropdownMenuItem(value: 'equipo_menor', child: Text('Equipo Menor')),
                    DropdownMenuItem(value: 'empleado', child: Text('Empleado / Operario')),
                    DropdownMenuItem(value: 'tercero', child: Text('Tercero / Otro')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _tipoDestino = val!;
                      _selectedVehicle = null;
                      _selectedEmployee = null;
                      _terceroController.clear();
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              if ((_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' || _tipoDestino == 'equipo_menor') && !isContextFixed) ...[
                _buildSectionTitle(_tipoDestino == 'vehiculo' ? 'VEHÍCULO *' : _tipoDestino == 'maquinaria' ? 'MAQUINARIA PESADA *' : 'EQUIPO MENOR *'),
                Consumer<FleetProvider>(
                  builder: (context, fleet, _) {
                    final options = fleet.vehiculos.where((v) => 
                      _tipoDestino == 'vehiculo' ? (v.categoria == 'vehiculo' || v.categoria == null || v.categoria!.isEmpty) : v.categoria == _tipoDestino
                    ).toList();
                    return SemanurAutocomplete<Vehiculo>(
                      options: options,
                      initialValue: _selectedVehicle,
                      hint: _tipoDestino == 'vehiculo' ? 'Seleccionar Vehículo...' : _tipoDestino == 'maquinaria' ? 'Seleccionar Maquinaria...' : 'Seleccionar Equipo Menor...',
                      displayStringForOption: (v) => '${v.placa} - ${v.marca} ${v.modelo}',
                      filterFn: (v, filter) =>
                          v.placa.toLowerCase().contains(filter) ||
                          v.marca.toLowerCase().contains(filter),
                      onSelected: (v) {
                        setState(() {
                          _selectedVehicle = v;
                          if (v.operadorAsignado != null) {
                            try {
                              _selectedEmployee = context.read<EmployeeProvider>().employees.firstWhere((e) => e.id == v.operadorAsignado!.id);
                            } catch (_) {
                              _selectedEmployee = v.operadorAsignado;
                            }
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' || _tipoDestino == 'equipo_menor') ...[
                _buildSectionTitle(_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' ? 'RESPONSABLE (EMPLEADO) *' : 'RESPONSABLE (EMPLEADO O TERCERO) *'),
                Consumer<EmployeeProvider>(
                  builder: (context, employeeProvider, _) {
                    return SemanurAutocomplete<Empleado>(
                      options: employeeProvider.employees,
                      initialValue: _selectedEmployee,
                      hint: _tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' ? 'Seleccionar empleado responsable...' : 'Nombre del empleado o tercero...',
                      displayStringForOption: (e) => e.nombreCompleto,
                      filterFn: (e, filter) => e.nombreCompleto.toLowerCase().contains(filter),
                      onSelected: (e) {
                        setState(() {
                          _selectedEmployee = e;
                          _terceroController.text = e.nombreCompleto;
                        });
                      },
                      onChanged: (val) {
                        _terceroController.text = val;
                        if (_selectedEmployee != null && val != _selectedEmployee!.nombreCompleto) {
                          setState(() => _selectedEmployee = null);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (_tipoDestino == 'empleado') ...[
                _buildSectionTitle('NOMBRE DEL EMPLEADO *'),
                TextFormField(
                  controller: _terceroController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_tipoDestino == 'tercero') ...[
                _buildSectionTitle('NOMBRE DEL TERCERO *'),
                TextFormField(
                  controller: _terceroController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre / Empresa',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _placaManualController,
                  decoration: const InputDecoration(
                    labelText: 'Placa del Vehículo (Opcional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildSectionTitle('DATOS DE ABASTECIMIENTO'),
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
              const SizedBox(height: 16),
              
              Consumer<InventoryProvider>(
                builder: (context, inventory, _) {
                  final producto = _findFuelProduct(inventory.productos, _tipoCombustible);
                  if (producto == null) return const SizedBox.shrink();

                  final bool lowStock = producto.stockActual <= producto.alertaStockMinimo;
                  final Color statusColor = lowStock ? Colors.redAccent : Colors.green;
                  final String unidad = producto.unidadMedida ?? 'GAL';
                  final double capacidad = producto.capacidadMaxima ?? 0;
                  final double ratio = capacidad > 0 ? (producto.stockActual / capacidad).clamp(0, 1) : 0.5;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
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
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(
                              '${producto.stockActual.toStringAsFixed(1)} $unidad',
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('CANTIDAD (GALONES) *'),
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.local_gas_station),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalFormatter],
              ),
              const SizedBox(height: 20),

              if (_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' || _tipoDestino == 'equipo_menor') ...[
                _buildSectionTitle('SEGUIMIENTO (OPCIONAL)'),
                Consumer<FleetProvider>(
                  builder: (context, fleet, _) {
                    Vehiculo? vehiculo = _selectedVehicle;
                    if (vehiculo == null && widget.vehiculoId != null) {
                      try {
                        vehiculo = fleet.vehiculos.firstWhere((v) => v.id == widget.vehiculoId);
                      } catch (_) {}
                    }
                    final isMach = vehiculo != null ? (vehiculo.categoria == 'maquinaria' || vehiculo.categoria == 'equipo_menor' || isMachinery(vehiculo.tipo)) : null;

                    return Row(
                      children: [
                        if (isMach == null || isMach == true)
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
                        if (isMach == null) const SizedBox(width: 10),
                        if (isMach == null || isMach == false)
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
                    );
                  }
                ),
                const SizedBox(height: 20),
              ],

              _buildSectionTitle('DESTINO O LABOR'),
              TextFormField(
                controller: _laborController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Ruta Norte, Arado, etc.',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('NOTAS / OBSERVACIONES'),
              TextFormField(
                controller: _notasController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Opcional...',
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
                      child: provider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('REGISTRAR TANQUEO'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
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
    return tipo.toLowerCase() == 'gasolina' ? fuels.gasolina : fuels.acpm;
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() => _localError = 'Complete los campos obligatorios (*)');
      return;
    }

    int? vehiculoId = widget.vehiculoId ?? _selectedVehicle?.id;
    int? empleadoId = (_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' || _tipoDestino == 'equipo_menor') ? _selectedEmployee?.id : null;
    final cantidad = _parseDouble(_cantidadController.text);

    if ((_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria' || _tipoDestino == 'equipo_menor') && vehiculoId == null) {
      setState(() => _localError = _tipoDestino == 'vehiculo' ? 'Vehículo no seleccionado' : _tipoDestino == 'maquinaria' ? 'Maquinaria no seleccionada' : 'Equipo Menor no seleccionado');
      return;
    }
    if ((_tipoDestino == 'vehiculo' || _tipoDestino == 'maquinaria') && empleadoId == null) {
      setState(() => _localError = 'Empleado responsable no seleccionado');
      return;
    }
    if (_tipoDestino == 'equipo_menor' && empleadoId == null && _terceroController.text.isEmpty) {
      setState(() => _localError = 'Ingrese o seleccione el responsable (empleado o tercero)');
      return;
    }
    if (_tipoDestino == 'empleado' && _terceroController.text.isEmpty) {
      setState(() => _localError = 'Ingrese nombre del empleado');
      return;
    }
    if (_tipoDestino == 'tercero' && _terceroController.text.isEmpty) {
      setState(() => _localError = 'Ingrese nombre del tercero');
      return;
    }

    if (cantidad == null || cantidad <= 0) {
      setState(() => _localError = 'Cantidad inválida');
      return;
    }

    final inventoryProvider = context.read<InventoryProvider>();
    final producto = _findFuelProduct(inventoryProvider.productos, _tipoCombustible);
    if (producto != null && cantidad > producto.stockActual) {
      setState(() => _localError = 'Stock insuficiente (${producto.stockActual.toStringAsFixed(1)})');
      return;
    }

    final success = await context.read<FuelProvider>().registrarTanqueo(
      vehiculoId: vehiculoId,
      empleadoId: empleadoId,
      terceroNombre: _terceroController.text.isNotEmpty ? _terceroController.text : null,
      placaManual: _placaManualController.text.isNotEmpty ? _placaManualController.text : null,
      tipoDestino: _tipoDestino,
      cantidad: cantidad,
      valor: 0,
      horometro: _parseDouble(_horometroController.text),
      kilometraje: _parseDouble(_kilometrajeController.text),
      notas: _notasController.text,
      labor: _laborController.text.isNotEmpty ? _laborController.text : null,
      productoId: null,
      tipoCombustible: _tipoCombustible,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Registro guardado correctamente'), backgroundColor: Colors.green),
        );
        _cantidadController.clear();
        _horometroController.clear();
        _kilometrajeController.clear();
        _notasController.clear();
        _terceroController.clear();
        _placaManualController.clear();
        _laborController.clear();
        FocusScope.of(context).unfocus();
        context.read<InventoryProvider>().fetchProductos(lowStock: false);
      } else {
        setState(() => _localError = context.read<FuelProvider>().error);
      }
    }
  }
}
