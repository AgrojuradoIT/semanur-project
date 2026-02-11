import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../../data/models/checklist_model.dart';
import '../providers/checklist_provider.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';

class ChecklistFormScreen extends StatefulWidget {
  final Checklist checklist;

  const ChecklistFormScreen({super.key, required this.checklist});

  @override
  State<ChecklistFormScreen> createState() => _ChecklistFormScreenState();
}

class _ChecklistFormScreenState extends State<ChecklistFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, dynamic> _respuestas = {}; // item_id: value
  final _observacionesController = TextEditingController();

  Vehiculo? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FleetProvider>().fetchVehiculos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.checklist.nombre)),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildVehicleSelector(),
                  const SizedBox(height: 24),
                  const Text(
                    'PUNTOS DE INSPECCIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.checklist.items.map(_buildItem),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _observacionesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones Generales',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.comment),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                  child: provider.isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'FINALIZAR INSPECCIÓN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSelector() {
    return Consumer<FleetProvider>(
      builder: (context, fleet, _) {
        // Filtrar vehículos si la lista tiene tipoVehiculo definido
        /*
        final vehiculos = widget.checklist.tipoVehiculo != null
            ? fleet.vehiculos.where((v) => v.tipo == widget.checklist.tipoVehiculo).toList()
            : fleet.vehiculos;
        */
        // Por simplificación mostramos todos por ahora
        final vehiculos = fleet.vehiculos;

        return DropdownButtonFormField<Vehiculo>(
          initialValue: _selectedVehicle,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Vehículo a Inspeccionar',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_car),
          ),
          items: vehiculos.map((v) {
            return DropdownMenuItem(
              value: v,
              child: Text('${v.placa} - ${v.marca} ${v.modelo}'),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedVehicle = val),
          validator: (val) => val == null ? 'Seleccione un vehículo' : null,
        );
      },
    );
  }

  Widget _buildItem(ChecklistItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (item.esCritico)
                  const Icon(
                    Icons.warning_amber,
                    color: Colors.orange,
                    size: 16,
                  ),
                if (item.esCritico) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.pregunta,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInputForItem(item),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForItem(ChecklistItem item) {
    if (item.tipoRespuesta == 'cumple_falla') {
      final currentValue = _respuestas[item.id]; // 'cumple', 'falla', null
      return RadioGroup<String>(
        groupValue: currentValue,
        onChanged: (val) => setState(() => _respuestas[item.id] = val),
        child: Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Cumple', style: TextStyle(fontSize: 14)),
                value: 'cumple',
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.green,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Falla', style: TextStyle(fontSize: 14)),
                value: 'falla',
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red,
              ),
            ),
          ],
        ),
      );
    } else if (item.tipoRespuesta == 'texto') {
      return TextFormField(
        onChanged: (val) => _respuestas[item.id] = val,
        decoration: const InputDecoration(
          hintText: 'Ingrese respuesta...',
          isDense: true,
        ),
      );
    } else if (item.tipoRespuesta == 'numero') {
      return TextFormField(
        keyboardType: TextInputType.number,
        onChanged: (val) => _respuestas[item.id] = val,
        decoration: const InputDecoration(
          hintText: 'Ingrese valor...',
          isDense: true,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe seleccionar un vehículo')),
      );
      return;
    }

    // Validar que todos los items tengan respuesta
    for (var item in widget.checklist.items) {
      if (!_respuestas.containsKey(item.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falta respuesta para: ${item.pregunta}')),
        );
        return;
      }
    }

    final data = {
      'lista_chequeo_id': widget.checklist.id,
      'vehiculo_id': _selectedVehicle!.id,
      'respuestas': _respuestas,
      'observaciones_generales': _observacionesController.text,
    };

    final success = await context.read<ChecklistProvider>().submitChecklist(
      data,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preoperacional guardado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${context.read<ChecklistProvider>().error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
