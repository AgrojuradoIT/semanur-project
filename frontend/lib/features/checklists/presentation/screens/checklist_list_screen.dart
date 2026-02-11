import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_theme.dart';
import '../providers/checklist_provider.dart';
import '../../data/models/checklist_model.dart';
import 'checklist_form_screen.dart';

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
      appBar: AppBar(
        title: Text(
          'CHECKLISTS Y PREOPERACIONALES',
          style: GoogleFonts.oswald(),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.checklists.isEmpty
          ? const Center(child: Text('No hay listas de chequeo disponibles'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.checklists.length,
              itemBuilder: (context, index) {
                final checklist = provider.checklists[index];
                return _buildChecklistCard(checklist);
              },
            ),
    );
  }

  Widget _buildChecklistCard(Checklist checklist) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.assignment, color: AppTheme.primaryYellow),
        ),
        title: Text(
          checklist.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: checklist.descripcion != null
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(checklist.descripcion!),
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChecklistFormScreen(checklist: checklist),
            ),
          );
        },
      ),
    );
  }
}
