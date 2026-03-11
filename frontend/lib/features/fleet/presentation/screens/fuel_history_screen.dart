import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fuel_provider.dart';
import '../../data/models/fuel_record_model.dart';
import 'package:intl/intl.dart';
import 'add_fuel_screen.dart';

class FuelHistoryScreen extends StatefulWidget {
  final int vehiculoId;
  final String placa;

  const FuelHistoryScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
  });

  @override
  State<FuelHistoryScreen> createState() => _FuelHistoryScreenState();
}

class _FuelHistoryScreenState extends State<FuelHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FuelProvider>().fetchRegistros(
        vehiculoId: widget.vehiculoId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial: ${widget.placa}')),
      body: Consumer<FuelProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.registros.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.registros.isEmpty) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.registros.isEmpty) {
            return const Center(
              child: Text('No hay registros de combustible para este vehículo'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.registros.length,
            itemBuilder: (context, index) {
              final RegistroCombustible reg = provider.registros[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(reg.fecha),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: reg.tipoCombustible == 'acpm'
                                      ? Colors.orange.withValues(alpha: 0.15)
                                      : Colors.blue.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  reg.tipoCombustible.toUpperCase(),
                                  style: TextStyle(
                                    color: reg.tipoCombustible == 'acpm'
                                        ? Colors.orange
                                        : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${reg.cantidadGalones} Gal',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                                ],
                                onSelected: (val) {
                                  if (val == 'delete') _confirmDelete(reg);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildInfoRow(
                        Icons.payments,
                        'Costo Total',
                        '\$${reg.valorTotal}',
                      ),
                      if (reg.horometroActual != null)
                        _buildInfoRow(
                          Icons.timer,
                          'Horómetro',
                          '${reg.horometroActual} h',
                        ),
                      if (reg.kilometrajeActual != null)
                        _buildInfoRow(
                          Icons.speed,
                          'Kilometraje',
                          '${reg.kilometrajeActual} km',
                        ),
                      if (reg.estacionServicio != null)
                        _buildInfoRow(
                          Icons.local_gas_station,
                          'Estación',
                          reg.estacionServicio!,
                        ),
                      if (reg.notas != null && reg.notas!.isNotEmpty)
                        _buildInfoRow(Icons.note, 'Notas', reg.notas!),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFuelScreen(
                vehiculoId: widget.vehiculoId,
                placa: widget.placa,
              ),
            ),
          );
        },
        label: const Text('Registrar Tanqueo'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(RegistroCombustible reg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Registro'),
        content: Text(
          '¿Estás seguro de eliminar el registro del ${DateFormat('dd/MM/yyyy').format(reg.fecha)} (${reg.cantidadGalones} gal)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<FuelProvider>().deleteRegistro(
                    reg.id,
                    vehiculoId: widget.vehiculoId,
                  );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Registro eliminado'
                          : 'Error al eliminar',
                    ),
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
