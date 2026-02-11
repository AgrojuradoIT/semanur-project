import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/features/auth/presentation/providers/employee_provider.dart';
import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'employee_form_screen.dart';
import 'employee_profile_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'todos';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEmployees();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEmployees() {
    context.read<EmployeeProvider>().loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = context.watch<EmployeeProvider>();
    final employees = employeeProvider.employees.where((emp) {
      final matchesSearch =
          emp.nombreCompleto.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          (emp.documento?.contains(_searchQuery) ?? false);

      if (_selectedRole == 'todos') return matchesSearch;

      final cargo = emp.cargo?.toLowerCase() ?? '';
      return matchesSearch && cargo.contains(_selectedRole.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchBar(),
                Expanded(
                  child: employeeProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : employees.isEmpty
                      ? Center(
                          child: Text(
                            'No se encontraron empleados',
                            style: GoogleFonts.inter(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          itemCount: employees.length,
                          itemBuilder: (context, index) {
                            return _buildEmployeeCard(employees[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
          );
          if (result == true) {
            _loadEmployees();
          }
        },
        backgroundColor: AppTheme.primaryYellow,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.black, size: 32),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  'DIRECTORIO DE PERSONAL',
                  style: GoogleFonts.oswald(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryYellow,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: _showFilterModal,
                icon: const Icon(Icons.filter_list, color: Colors.white70),
                iconSize: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Buscar empleado...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.white38),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(Empleado employee) {
    return GestureDetector(
      onTap: () => _editEmployee(employee),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryYellow, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(
                        employee.fotoUrl ??
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(employee.nombreCompleto.isNotEmpty ? employee.nombreCompleto : 'U')}&background=random&color=fff',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: employee.estado == 'activo'
                          ? Colors.green
                          : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1E1E1E),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.nombreCompleto,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    employee.dependencia ?? 'Sin área asignada',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildRoleBadge(employee.cargo),
                ],
              ),
            ),
            // Actions
            Row(
              children: [
                _buildActionButton(Icons.call, () {
                  // Implement call functionality
                }),
                const SizedBox(width: 8),
                _buildActionButton(Icons.visibility, () {
                  _editEmployee(employee);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.transparent,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white54, size: 22),
        onPressed: onTap,
        splashRadius: 24,
      ),
    );
  }

  Widget _buildRoleBadge(String? cargo) {
    String label = (cargo ?? 'Sin Cargo').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryYellow,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por Cargo',
                style: GoogleFonts.oswald(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFilterOption('Todos', 'todos'),
                  _buildFilterOption('Mecánicos', 'mecanico'),
                  _buildFilterOption('Operadores', 'operador'),
                  _buildFilterOption('Administrativos', 'admin'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String label, String value) {
    final isSelected = _selectedRole == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRole = value;
        });
        Navigator.pop(context);
      },
      selectedColor: AppTheme.primaryYellow,
      backgroundColor: Colors.white10,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  void _editEmployee(Empleado employee) async {
    // Navegar al perfil, y esperar si se hizo alguna edición desde allá
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeProfileScreen(employee: employee),
      ),
    );
    if (result == true) {
      _loadEmployees();
    }
  }
}
