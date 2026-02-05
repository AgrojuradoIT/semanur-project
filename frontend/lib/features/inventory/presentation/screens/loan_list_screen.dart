import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/presentation/providers/loan_provider.dart';
import 'package:frontend/features/inventory/data/models/loan_model.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_loan_screen.dart';

class LoanListScreen extends StatefulWidget {
  const LoanListScreen({super.key});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LoanProvider>().fetchPrestamos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HERRAMIENTAS PRESTADAS', style: GoogleFonts.oswald()),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryYellow,
          labelColor: AppTheme.primaryYellow,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'ACTIVOS', icon: Icon(Icons.pending_actions)),
            Tab(text: 'HISTORIAL', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: Consumer<LoanProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.prestamos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.prestamos.isEmpty) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildLoanList(
                provider.prestamos
                    .where((p) => p.estado == 'prestado')
                    .toList(),
              ),
              _buildLoanList(
                provider.prestamos
                    .where((p) => p.estado != 'prestado')
                    .toList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddLoanScreen()),
          );
        },
        label: const Text('Nuevo Préstamo'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoanList(List<PrestamoHerramienta> loans) {
    if (loans.isEmpty) {
      return const Center(child: Text('No hay registros en esta sección'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ExpansionTile(
            collapsedIconColor: Colors.white70,
            iconColor: AppTheme.primaryYellow,
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(
                loan.estado,
              ).withValues(alpha: 0.1),
              child: Icon(Icons.build, color: _getStatusColor(loan.estado)),
            ),
            title: Text(
              loan.producto?.nombre ?? 'Herramienta desconocida',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Mecánico: ${loan.mecanicoNombre ?? 'Desconocido'}',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd/MM').format(loan.fechaPrestamo),
                  style: const TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('HH:mm').format(loan.fechaPrestamo),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Cantidad', '${loan.cantidad}'),
                    _buildDetailRow(
                      'Autorizado por',
                      loan.adminNombre ?? 'Admin',
                    ),
                    _buildDetailRow(
                      'Estado',
                      loan.estado.toUpperCase(),
                      color: _getStatusColor(loan.estado),
                    ),
                    if (loan.fechaDevolucion != null)
                      _buildDetailRow(
                        'Devuelto el',
                        DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(loan.fechaDevolucion!),
                      ),
                    if (loan.notas != null && loan.notas!.isNotEmpty)
                      _buildDetailRow('Notas', loan.notas!),
                    const SizedBox(height: 16),
                    if (loan.estado == 'prestado')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showReturnDialog(loan),
                          icon: const Icon(
                            Icons.assignment_return,
                            color: Colors.black,
                          ),
                          label: Text(
                            'REGISTRAR DEVOLUCIÓN',
                            style: GoogleFonts.oswald(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryYellow,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado) {
      case 'prestado':
        return Colors.orange;
      case 'devuelto':
        return Colors.green;
      case 'dañado':
        return Colors.red;
      case 'perdido':
        return Colors.black87;
      default:
        return Colors.grey;
    }
  }

  void _showReturnDialog(PrestamoHerramienta loan) {
    String selectedEstado = 'devuelto';
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Text(
            'REGISTRAR DEVOLUCIÓN',
            style: GoogleFonts.oswald(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿En qué estado regresa: ${loan.producto?.nombre}?',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(selectedEstado),
                initialValue: selectedEstado,
                dropdownColor: AppTheme.surfaceDark,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                    value: 'devuelto',
                    child: Text('Devuelto (Buen estado)'),
                  ),
                  DropdownMenuItem(value: 'dañado', child: Text('Dañado')),
                  DropdownMenuItem(value: 'perdido', child: Text('Perdido')),
                ],
                onChanged: (val) => setState(() => selectedEstado = val!),
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryYellow),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryYellow),
                  ),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final success = await context
                    .read<LoanProvider>()
                    .devolverHerramienta(
                      loan.id,
                      selectedEstado,
                      notas: notesController.text,
                    );

                navigator.pop();
                if (success) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Devolución registrada con éxito'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryYellow,
                foregroundColor: Colors.black,
              ),
              child: const Text('CONFIRMAR'),
            ),
          ],
        ),
      ),
    );
  }
}
