import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/fleet/presentation/providers/checklist_provider.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/fleet/data/models/checklist_model.dart';
import 'package:frontend/features/fleet/presentation/screens/checklist_detail_screen.dart';

class ChecklistListScreen extends StatefulWidget {
  const ChecklistListScreen({super.key});

  @override
  State<ChecklistListScreen> createState() => _ChecklistListScreenState();
}

class _ChecklistListScreenState extends State<ChecklistListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChecklistProvider>().fetchChecklists();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChecklistProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          'HISTORIAL PREOPERACIONAL',
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
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryYellow),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: provider.checklists.length,
              separatorBuilder: (context, index) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final checklist = provider.checklists[index];
                return _buildChecklistCard(context, checklist);
              },
            ),
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    ChecklistPreoperacional checklist,
  ) {
    // Determinar si hay alerta (esto es visual por ahora, idealmente vendría del back o calculado)
    // Asumimos alerta si el estado no es "Aprobado" (ajustar según lógica real)
    final bool hasIssues = checklist.estado.toLowerCase() != 'aprobado';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChecklistDetailScreen(checklist: checklist),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(15),
          border: Border(
            left: BorderSide(
              color: hasIssues ? Colors.red : Colors.green,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    checklist.vehiculoPlaca ?? 'VEHÍCULO S/N',
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasIssues
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasIssues ? 'REVISAR' : 'APROBADO',
                    style: TextStyle(
                      color: hasIssues ? Colors.red : Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.textGray, size: 14),
                const SizedBox(width: 5),
                Text(
                  checklist.usuarioNombre ?? 'Desconocido',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 15),
                const Icon(
                  Icons.calendar_today,
                  color: AppTheme.textGray,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(checklist.fecha),
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
