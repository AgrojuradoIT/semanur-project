import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/fleet/presentation/providers/checklist_provider.dart'
    as fleet_cp;
import 'package:frontend/features/fleet/presentation/providers/fuel_provider.dart';
import 'package:frontend/features/history/data/models/history_item.dart';
import 'package:frontend/features/inventory/presentation/providers/loan_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/movement_provider.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final MovementProvider _movementProvider;
  final WorkshopProvider _workshopProvider;
  final FuelProvider _fuelProvider;
  final LoanProvider _loanProvider;
  final fleet_cp.ChecklistProvider _checklistProvider;

  List<HistoryItem> _historyItems = [];
  bool _isLoading = false;

  HistoryProvider(
    this._movementProvider,
    this._workshopProvider,
    this._fuelProvider,
    this._loanProvider,
    this._checklistProvider,
  );

  List<HistoryItem> get historyItems => _historyItems;
  bool get isLoading => _isLoading;

  Future<void> fetchAllHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<HistoryItem> allItems = [];

      if (_movementProvider.movimientos.isEmpty) {
        await _movementProvider.fetchMovimientos();
      }
      for (final mov in _movementProvider.movimientos) {
        final isIngreso = mov.tipo.toLowerCase() == 'ingreso';
        allItems.add(
          HistoryItem(
            id: 'mov_${mov.id}',
            originalId: mov.id.toString(),
            title:
                '${mov.tipo.toUpperCase()} - ${mov.producto?.nombre ?? 'Producto'}',
            description: '${mov.motivo} (${mov.cantidad} unid)',
            user: _normalizeActor(mov.usuarioNombre, fallback: 'Sistema'),
            timestamp: mov.createdAt,
            module: 'Inventario',
            actionType: HistoryActionType.create,
            icon: isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIngreso ? Colors.green : Colors.orange,
            reference: 'MOV-${mov.id}',
          ),
        );
      }

      if (_workshopProvider.ordenes.isEmpty) {
        await _workshopProvider.fetchOrdenes();
      }
      for (final ot in _workshopProvider.ordenes) {
        final String actor = ot.mecanico != null
            ? '${ot.mecanico!.nombres} ${ot.mecanico!.apellidos}'.trim()
            : 'Sistema';

        allItems.add(
          HistoryItem(
            id: 'ot_${ot.id}',
            originalId: ot.id.toString(),
            title: 'OT #${ot.id} - ${ot.vehiculo?.placa ?? 'Vehiculo'}',
            description: 'Estado: ${ot.estado} - ${ot.descripcion}',
            user: _normalizeActor(actor, fallback: 'Sistema'),
            timestamp: ot.fechaInicio,
            module: 'Taller',
            actionType: HistoryActionType.status,
            icon: Icons.construction,
            color: Colors.blue,
            reference: 'OT-${ot.id}',
          ),
        );
      }

      if (_fuelProvider.registros.isEmpty) {
        await _fuelProvider.fetchRegistros();
      }
      for (final fuel in _fuelProvider.registros) {
        allItems.add(
          HistoryItem(
            id: 'fuel_${fuel.id}',
            originalId: fuel.id.toString(),
            title: 'Combustible - ${fuel.vehiculoPlaca ?? 'N/A'}',
            description:
                '${fuel.cantidadGalones} gal - ${fuel.estacionServicio ?? 'Estacion'}',
            user: _normalizeActor(fuel.usuarioNombre, fallback: 'Sistema'),
            timestamp: fuel.fecha,
            module: 'Flota',
            actionType: HistoryActionType.create,
            icon: Icons.local_gas_station,
            color: AppTheme.primaryYellow,
            reference: 'FUEL-${fuel.id}',
          ),
        );
      }

      if (_loanProvider.prestamos.isEmpty) {
        await _loanProvider.fetchPrestamos();
      }
      for (final loan in _loanProvider.prestamos) {
        allItems.add(
          HistoryItem(
            id: 'loan_${loan.id}',
            originalId: loan.id.toString(),
            title: 'Prestamo - ${loan.producto?.nombre ?? 'Herramienta'}',
            description:
                '${loan.cantidad} unid a ${loan.mecanicoNombre ?? 'Mecanico'}',
            user: _normalizeActor(loan.adminNombre, fallback: 'Admin'),
            timestamp: loan.fechaPrestamo,
            module: 'Inventario',
            actionType: HistoryActionType.session,
            icon: Icons.handyman,
            color: Colors.purple,
            reference: 'PREST-${loan.id}',
          ),
        );
      }

      if (_checklistProvider.checklists.isEmpty) {
        await _checklistProvider.fetchChecklists();
      }
      for (final cl in _checklistProvider.checklists) {
        allItems.add(
          HistoryItem(
            id: 'cl_${cl.id}',
            originalId: cl.id.toString(),
            title: 'Preoperacional - ${cl.vehiculoPlaca ?? 'Vehiculo'}',
            description: 'Estado: ${cl.estado}',
            user: _normalizeActor(cl.usuarioNombre, fallback: 'Conductor'),
            timestamp: cl.fecha,
            module: 'Flota',
            actionType: HistoryActionType.status,
            icon: Icons.playlist_add_check,
            color: cl.estado == 'Aprobado' ? Colors.teal : Colors.redAccent,
            reference: 'CHK-${cl.id}',
          ),
        );
      }

      allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _historyItems = allItems;
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _normalizeActor(String? raw, {required String fallback}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return fallback;
    return value;
  }
}
