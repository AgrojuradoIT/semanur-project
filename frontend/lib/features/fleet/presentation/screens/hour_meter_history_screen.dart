import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../providers/hour_meter_provider.dart';
import '../../data/models/hour_meter_record_model.dart';

class HourMeterHistoryScreen extends StatefulWidget {
  final int vehiculoId;
  final String placa;

  const HourMeterHistoryScreen({
    super.key,
    required this.vehiculoId,
    required this.placa,
  });

  @override
  State<HourMeterHistoryScreen> createState() => _HourMeterHistoryScreenState();
}

class _HourMeterHistoryScreenState extends State<HourMeterHistoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HorometroProvider>().fetchRegistros(widget.vehiculoId);
    });
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          'REGISTRAR HORÓMETRO',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nuevo Valor',
                  labelStyle: TextStyle(color: AppTheme.textGray),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.surfaceDark2),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notas / Observaciones',
                  labelStyle: TextStyle(color: AppTheme.textGray),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<HorometroProvider>().registrarHorometro(
      vehiculoId: widget.vehiculoId,
      valorNuevo: double.parse(_valueController.text),
      notas: _notesController.text,
    );

    if (mounted && success) {
      Navigator.pop(context);
      _valueController.clear();
      _notesController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro guardado exitosamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HorometroProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildList(provider.registros),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.primaryYellow,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildList(List<RegistroHorometro> registros) {
    if (registros.isEmpty) {
      return const Center(
        child: Text(
          'No hay registros de horómetro',
          style: TextStyle(color: AppTheme.textGray),
        ),
      );
    }

    return ListView.builder(
      itemCount: registros.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final r = registros[index];
        final diff = r.valorNuevo - r.valorAnterior;

        return Card(
          color: AppTheme.surfaceDark,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: AppTheme.surfaceDark2.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LECTURA: ${r.valorNuevo} HORAS',
                          style: GoogleFonts.oswald(
                            color: AppTheme.primaryYellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt),
                          style: const TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
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
                        '+$diff H',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (r.notas != null && r.notas!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.surfaceDark2),
                  const SizedBox(height: 8),
                  Text(
                    r.notas!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: AppTheme.textGray,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.usuario?.name ?? 'Semanur User',
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
