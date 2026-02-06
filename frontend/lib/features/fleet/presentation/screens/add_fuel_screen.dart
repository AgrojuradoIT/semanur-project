import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/data/models/product_model.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import '../providers/fuel_provider.dart';

class AddFuelScreen extends StatefulWidget {
  final int vehiculoId;
  final String placa;

  const AddFuelScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
  });

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

  bool _isInternal = true;
  Producto? _selectedProduct;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().fetchProductos();
      // Initialize text for internal mode
      if (_isInternal) {
        _estacionController.text = 'Inventario Interno';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tanqueo: ${widget.placa}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
            const Text(
              'SEGUIMIENTO (OPCIONAL)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
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
      final success = await context.read<FuelProvider>().registrarTanqueo(
        vehiculoId: widget.vehiculoId,
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
