import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/fleet/data/models/checklist_model.dart';
import 'package:intl/intl.dart';

class ChecklistDetailScreen extends StatelessWidget {
  final ChecklistPreoperacional checklist;

  const ChecklistDetailScreen({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          'DETALLE PREOPERACIONAL',
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 25),
          _buildInfoSection(),
          const SizedBox(height: 25),
          _buildChecklistItems(),
          if (checklist.observaciones != null &&
              checklist.observaciones!.isNotEmpty)
            _buildObservations(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool hasAlert = checklist.hasAlert;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border(
          left: BorderSide(
            color: hasAlert ? Colors.red : Colors.green,
            width: 6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                checklist.estado.toUpperCase(),
                style: GoogleFonts.oswald(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: hasAlert ? Colors.red : Colors.green,
                ),
              ),
              Icon(
                hasAlert
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                color: hasAlert ? Colors.red : Colors.green,
                size: 30,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'ID: #${checklist.id}',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'VEHÍCULO',
            checklist.vehiculoPlaca ?? 'N/A',
            isPrimary: true,
          ),
          const Divider(color: AppTheme.surfaceDark2, height: 20),
          _buildInfoRow('OPERADOR', checklist.usuarioNombre ?? 'N/A'),
          _buildInfoRow(
            'FECHA',
            DateFormat('dd/MM/yyyy HH:mm').format(checklist.fecha),
          ),
          if (checklist.horometroActual != null)
            _buildInfoRow('HORÓMETRO', '${checklist.horometroActual} H'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: isPrimary ? 18 : 14,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItems() {
    if (checklist.checklistData.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INSPECCIÓN',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryYellow,
          ),
        ),
        const SizedBox(height: 15),
        ...checklist.checklistData.entries.map((entry) {
          // entry.value can be bool or other types depending on legacy, assuming bool now based on screen
          final bool isOk = entry.value == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOk
                    ? Colors.transparent
                    : Colors.red.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isOk
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    isOk ? 'OK' : 'FALLO',
                    style: TextStyle(
                      color: isOk ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildObservations() {
    return Container(
      margin: const EdgeInsets.only(top: 25),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OBSERVACIONES',
            style: TextStyle(
              color: AppTheme.textGray,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            checklist.observaciones!,
            style: const TextStyle(
              color: Colors.white,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
