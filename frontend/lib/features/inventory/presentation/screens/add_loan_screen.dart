import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/inventory/presentation/providers/loan_provider.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedProductId;
  int? _selectedMecanicoId;
  final _cantidadController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  List<User> _users = [];
  bool _loadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    // Evita notifyListeners() durante el ciclo de build inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inventory = context.read<InventoryProvider>();
      if (inventory.productos.isEmpty && !inventory.isLoading) {
        inventory.fetchProductos();
      }
    });
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await context.read<AuthRepository>().getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _loadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Prestamo')),
      body: Consumer<InventoryProvider>(
        builder: (context, invProvider, child) {
          if (invProvider.isLoading || _loadingUsers) {
            return const Center(child: CircularProgressIndicator());
          }

          final tools = invProvider.productos
              .where(
                (p) =>
                    p.categoria?.nombre.toLowerCase().contains('herramienta') ??
                    false,
              )
              .toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'DATOS DEL PRESTAMO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),

                // Seleccion de Herramienta
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Herramienta',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.build),
                  ),
                  items: tools
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.nombre} (Stock: ${p.stockActual})',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedProductId = val),
                  validator: (val) =>
                      val == null ? 'Seleccione una herramienta' : null,
                ),
                const SizedBox(height: 20),

                // Seleccion de Mecanico
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Mecanico / Operario',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: _users
                      .map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedMecanicoId = val),
                  validator: (val) =>
                      val == null ? 'Seleccione un responsable' : null,
                ),
                const SizedBox(height: 20),

                // Cantidad
                TextFormField(
                  controller: _cantidadController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Ingrese la cantidad';
                    }
                    if (double.tryParse(val) == null) {
                      return 'Ingrese un numero valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Notas
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas / Observaciones',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),

                Consumer<LoanProvider>(
                  builder: (context, loanProvider, child) {
                    return SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loanProvider.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: loanProvider.isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'REGISTRAR PRESTAMO',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<LoanProvider>().registrarPrestamo(
        productoId: _selectedProductId!,
        mecanicoId: _selectedMecanicoId!,
        cantidad: double.parse(_cantidadController.text),
        notas: _notesController.text,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prestamo registrado correctamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${context.read<LoanProvider>().error}'),
            ),
          );
        }
      }
    }
  }
}

