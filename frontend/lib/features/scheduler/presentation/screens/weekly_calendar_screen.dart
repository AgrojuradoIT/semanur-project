import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'incident_report_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../providers/programacion_provider.dart';
import 'package:frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:frontend/features/auth/data/models/user_model.dart';
import '../../data/models/programacion_model.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/fleet/data/models/vehicle_model.dart';
import 'package:intl/intl.dart';

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  DateTime _currentWeekStart = DateTime.now();

  // Color Palette from Design
  static const Color primaryColor = Color(0xFFFFD900); // Yellow
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceLighter = Color(0xFF2C2C2C);

  static const Color stateNormal = Color(0xFF81D4FA); // Light Blue
  static const Color stateIssue = Color(0xFFEF9A9A); // Light Red
  static const Color statePaused = Color(0xFFB0BEC5); // Gray
  static const Color stateDone = Color(0xFFA5D6A7); // Light Green

  // Scroll Controllers for Synchronization
  late LinkedScrollControllerGroup _verticalControllers;
  late ScrollController _employeesListController;
  late ScrollController _gridVerticalController;

  late LinkedScrollControllerGroup _horizontalControllers;
  late ScrollController _daysHeaderController;
  late ScrollController _gridHorizontalController;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );

    // Init Sync Controllers
    _verticalControllers = LinkedScrollControllerGroup();
    _employeesListController = _verticalControllers.addAndGet();
    _gridVerticalController = _verticalControllers.addAndGet();

    _horizontalControllers = LinkedScrollControllerGroup();
    _daysHeaderController = _horizontalControllers.addAndGet();
    _gridHorizontalController = _horizontalControllers.addAndGet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUsers();
      context.read<FleetProvider>().fetchVehiculos();
      _fetchSchedule();
    });
  }

  @override
  void dispose() {
    _employeesListController.dispose();
    _gridVerticalController.dispose();
    _daysHeaderController.dispose();
    _gridHorizontalController.dispose();
    super.dispose();
  }

  void _fetchSchedule() {
    context.read<ProgramacionProvider>().fetchWeekSchedule(_currentWeekStart);
  }

  void _changeWeek(int weeks) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * weeks));
    });
    _fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    // Theme Overrides for this screen specifically
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: backgroundDark,
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      child: Scaffold(
        backgroundColor: backgroundDark,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildWeekNavigator(),
              Expanded(
                child: Consumer2<UserProvider, ProgramacionProvider>(
                  builder: (context, userProvider, progProvider, child) {
                    if (userProvider.isLoading || progProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      );
                    }

                    if (progProvider.error != null) {
                      return _buildErrorView(progProvider.error!);
                    }

                    final employees = _getFilteredEmployees(userProvider.users);

                    return Column(
                      children: [
                        // Sticky Header Row (Empty Corner + Days)
                        SizedBox(
                          height: 80,
                          child: Row(
                            children: [
                              _buildCornerCell(),
                              Expanded(
                                child: ListView.builder(
                                  controller: _daysHeaderController,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 7,
                                  itemBuilder: (context, index) {
                                    final day = _currentWeekStart.add(
                                      Duration(days: index),
                                    );
                                    return _buildDayHeaderCell(day);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Main Content (Sticky Employee Column + Scrollable Grid)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sticky Employee Column
                              SizedBox(
                                width: 140,
                                child: ListView.builder(
                                  controller: _employeesListController,
                                  itemCount: employees.length,
                                  padding: EdgeInsets.zero, // Remove defaults
                                  physics:
                                      const ClampingScrollPhysics(), // Prevent bounce desync
                                  itemBuilder: (context, index) {
                                    return _buildEmployeeLeftCell(
                                      employees[index],
                                    );
                                  },
                                ),
                              ),
                              // The Grid
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _gridVerticalController,
                                  physics:
                                      const ClampingScrollPhysics(), // Prevent bounce desync
                                  child: SingleChildScrollView(
                                    controller: _gridHorizontalController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const ClampingScrollPhysics(),
                                    child: Column(
                                      children: employees.map((employee) {
                                        return Row(
                                          children: List.generate(7, (
                                            dayIndex,
                                          ) {
                                            final day = _currentWeekStart.add(
                                              Duration(days: dayIndex),
                                            );
                                            return _buildGridCell(
                                              employee,
                                              day,
                                              progProvider.programacion,
                                            );
                                          }),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: surfaceDark,
        border: Border(bottom: BorderSide(color: Colors.white10)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
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
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PROGRAMACIÓN SEMANAL',
                    style: GoogleFonts.oswald(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white70),
                onPressed: _fetchSchedule,
              ),
              const SizedBox(width: 10),
              // User Avatar Placeholder
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, Colors.orange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                // In real app, put user image here
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: backgroundDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigator() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    String dateFormat(DateTime date) =>
        '${const ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'][date.month - 1]} ${date.day}';

    return Container(
      color: backgroundDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white10),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _navButton(Icons.chevron_left, () => _changeWeek(-1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        'SEMANA ${_getWeekNumber(_currentWeekStart)}',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${dateFormat(_currentWeekStart)} - ${dateFormat(weekEnd)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _navButton(Icons.chevron_right, () => _changeWeek(1)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_view_week, size: 16, color: primaryColor),
                SizedBox(width: 6),
                Text(
                  'VISTA ACTUAL',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getWeekNumber(DateTime date) {
    int dayOfYear = int.parse(DateFormat("D").format(date));
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white60, size: 20),
      ),
    );
  }

  Widget _buildCornerCell() {
    return Container(
      width: 140,
      height: 80,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: surfaceDark,
        border: Border(
          right: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: const Text(
        'EMPLEADO',
        style: TextStyle(
          color: Colors.white38,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDayHeaderCell(DateTime day) {
    final isToday =
        day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day;
    final textColor = isToday ? primaryColor : Colors.white;
    final bgColor = isToday
        ? primaryColor.withValues(alpha: 0.1)
        : surfaceLighter.withValues(alpha: 0.5);

    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          right: const BorderSide(color: Colors.white10),
          bottom: BorderSide(
            color: isToday ? primaryColor : Colors.white10,
            width: isToday ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            const [
              'LUN',
              'MAR',
              'MIE',
              'JUE',
              'VIE',
              'SAB',
              'DOM',
            ][day.weekday - 1],
            style: TextStyle(
              fontSize: 11,
              color: isToday ? primaryColor : Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day.day.toString(),
            style: TextStyle(
              fontSize: 20,
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeLeftCell(User employee) {
    // Determine avatar color based on name
    final avatarColor =
        Colors.primaries[employee.name.hashCode % Colors.primaries.length];

    return Container(
      width: 140,
      height: 100, // Fixed height matching grid cells
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: surfaceDark,
        border: Border(
          right: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, offset: Offset(2, 0), blurRadius: 4),
        ], // Drop shadow to right
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  employee.name
                      .substring(0, min(2, employee.name.length))
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  employee.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            employee.cargo ?? employee.role ?? 'Personal',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          // Fake progress bar just for aesthetics like in design
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (employee.id % 5 + 5) / 10.0, // Randomish width
              child: Container(
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCell(
    User employee,
    DateTime day,
    List<Programacion> allTasks,
  ) {
    final empleadoBackendId = employee.userId ?? employee.id;
    final tasks = allTasks
        .where(
          (t) =>
              t.empleadoId == empleadoBackendId &&
              t.fecha.year == day.year &&
              t.fecha.month == day.month &&
              t.fecha.day == day.day,
        )
        .toList();

    return Container(
      width: 120,
      height: 100,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.white10),
          bottom: BorderSide(color: Colors.white10),
        ),
      ),
      child: tasks.isEmpty
          ? _buildEmptyCellAddButton(employee, day)
          : Column(
              children: tasks
                  .map((t) => Expanded(child: _buildTaskCard(t)))
                  .toList(),
            ),
    );
  }

  Widget _buildEmptyCellAddButton(User employee, DateTime day) {
    return InkWell(
      onTap: () => _showGlobalCreateTaskDialog(
        context,
        preSelectedEmployee: employee,
        preSelectedDate: day,
      ),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white10, style: BorderStyle.solid),
        ),
        // Hover effect mimics usually done with MouseRegion, keeping simple here
        child: const Icon(Icons.add, color: Colors.white12, size: 20),
      ),
    );
  }

  Widget _buildTaskCard(Programacion task) {
    Color cardColor = stateNormal;
    Color textColor = backgroundDark;
    IconData icon = Icons.settings;

    if (task.esNovedad) {
      cardColor = stateIssue;
      icon = Icons.warning;
    } else if (task.estado == 'pausado') {
      cardColor = statePaused;
      icon = Icons.pause;
    } else if (task.estado == 'completado') {
      cardColor = stateDone;
      icon = Icons.check_circle;
    }

    Widget buildMenu() {
      return SizedBox(
        width: 20,
        height: 20,
        child: PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 12, color: textColor),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              height: 32,
              child: Text('Editar', style: TextStyle(fontSize: 12)),
            ),
            const PopupMenuItem(
              value: 'delete',
              height: 32,
              child: Text('Eliminar', style: TextStyle(fontSize: 12)),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showGlobalCreateTaskDialog(context, existingTask: task);
            } else if (value == 'delete') {
              _deleteTask(task);
            }
          },
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(6),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        border: task.esNovedad
            ? const Border(left: BorderSide(color: Colors.red, width: 4))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Compact View for tight spaces
          if (constraints.maxHeight < 35) {
            return Row(
              children: [
                buildMenu(),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.labor,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }

          // Full View
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '08:00', // Hardcoded time
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  buildMenu(),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      task.labor,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (task.ubicacion != null && constraints.maxHeight > 55)
                Text(
                  task.ubicacion!,
                  style: TextStyle(
                    fontSize: 9,
                    color: textColor.withValues(alpha: 0.8),
                    fontFamily: 'Monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: surfaceDark,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: surfaceLighter,
                foregroundColor: const Color(0xFFEF9A9A),
                side: const BorderSide(color: Color(0xFFB71C1C)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => _showReportNovedadDialog(context),
              icon: const Icon(Icons.warning, size: 20),
              label: const Text(
                'NOVEDAD',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: backgroundDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                shadowColor: primaryColor.withValues(alpha: 0.5),
                elevation: 8,
              ),
              onPressed: () => _showGlobalCreateTaskDialog(context),
              icon: const Icon(Icons.calendar_today, size: 20),
              label: const Text(
                'PROGRAMAR',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Logic Helpers ---

  List<User> _getFilteredEmployees(List<User> allUsers) {
    final filtered = allUsers
        .where(
          (u) =>
              u.role == 'mecanico' || u.role == 'operador' || u.cargo != null,
        )
        .toList();
    filtered.sort(
      (a, b) => (a.dependencia ?? '').compareTo(b.dependencia ?? ''),
    );
    return filtered;
  }

  int min(int a, int b) => a < b ? a : b;

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: stateIssue, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error de Carga',
            style: GoogleFonts.oswald(fontSize: 20, color: Colors.white),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: backgroundDark,
            ),
            onPressed: _fetchSchedule,
            child: const Text('REINTENTAR'),
          ),
        ],
      ),
    );
  }

  // --- Dialogs (Adapted from original code but styled if needed, keeping functionality) ---

  void _deleteTask(Programacion task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceDark,
        title: Text(
          'Confirmar Eliminación',
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta tarea?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: stateIssue,
              foregroundColor: backgroundDark,
            ),
            onPressed: () async {
              final provider = context.read<ProgramacionProvider>();
              final error = await provider.deleteProgramacion(task.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: stateIssue,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarea eliminada')),
                  );
                }
              }
            },
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  void _showGlobalCreateTaskDialog(
    BuildContext context, {
    User? preSelectedEmployee,
    DateTime? preSelectedDate,
    Programacion? existingTask,
  }) {
    final laborController = TextEditingController(text: existingTask?.labor);
    final ubicacionController = TextEditingController(
      text: existingTask?.ubicacion,
    );

    User? selectedEmployee = preSelectedEmployee;
    // Find pre-selected employee if editing
    if (existingTask != null) {
      try {
        final userProvider = context.read<UserProvider>();
        selectedEmployee = userProvider.users.firstWhere(
          (u) => u.id == existingTask.empleadoId,
        );
      } catch (_) {}
    }

    Vehiculo? selectedVehicle;
    // Find pre-selected vehicle if editing
    if (existingTask != null && existingTask.vehiculoId != null) {
      try {
        final fleetProvider = context.read<FleetProvider>();
        selectedVehicle = fleetProvider.vehiculos.firstWhere(
          (v) => v.id == existingTask.vehiculoId,
        );
      } catch (_) {}
    }

    DateTime selectedDate =
        existingTask?.fecha ?? preSelectedDate ?? DateTime.now();
    bool crearOT = false; // Usually false when editing unless explicitly wanted
    bool isMultiDay = false;
    List<int> selectedWeekDays = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          void toggleDay(int day) {
            setState(() {
              if (selectedWeekDays.contains(day)) {
                selectedWeekDays.remove(day);
              } else {
                selectedWeekDays.add(day);
              }
            });
          }

          return AlertDialog(
            backgroundColor: surfaceDark,
            title: Text(
              existingTask != null ? 'Editar Tarea' : 'Programar Tarea',
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee Dropdown
                  Text(
                    'Empleado',
                    style: GoogleFonts.spaceGrotesk(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Consumer<UserProvider>(
                    builder: (context, provider, _) {
                      return DropdownButtonFormField<User>(
                        initialValue: selectedEmployee,
                        isExpanded: true,
                        decoration: _inputDecoration(hint: 'Empleado Afectado'),
                        items: provider.users.map((User u) {
                          return DropdownMenuItem<User>(
                            value: u,
                            child: Text(u.name),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedEmployee = val),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Vehículo (Opcional)',
                    style: GoogleFonts.spaceGrotesk(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Consumer<FleetProvider>(
                    builder: (context, fleet, _) {
                      return DropdownButtonFormField<Vehiculo>(
                        initialValue: selectedVehicle,
                        isExpanded: true,
                        decoration: _inputDecoration(
                          hint: 'Seleccionar Vehículo',
                        ),
                        items: fleet.vehiculos.map((v) {
                          return DropdownMenuItem(
                            value: v,
                            child: Text('${v.placa} - ${v.modelo}'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedVehicle = val),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  // Date Picker
                  Text(
                    'Fecha',
                    style: GoogleFonts.spaceGrotesk(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: primaryColor,
                                onPrimary: backgroundDark,
                                surface: surfaceLighter,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd / MMM / yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Only show Multi Day if NOT editing (too complex for edit)
                  if (existingTask == null) ...[
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            activeColor: primaryColor,
                            checkColor: backgroundDark,
                            value: isMultiDay,
                            onChanged: (val) {
                              setState(() {
                                isMultiDay = val!;
                                if (isMultiDay && selectedWeekDays.isEmpty) {
                                  selectedWeekDays.add(selectedDate.weekday);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Repetir varios días',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    if (isMultiDay)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(7, (index) {
                            final day = index + 1;
                            final isSelected = selectedWeekDays.contains(day);
                            final labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                            return GestureDetector(
                              onTap: () => toggleDay(day),
                              child: Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? primaryColor
                                        : Colors.white24,
                                  ),
                                ),
                                child: Text(
                                  labels[index],
                                  style: TextStyle(
                                    color: isSelected
                                        ? backgroundDark
                                        : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],

                  const SizedBox(height: 15),
                  Text(
                    'Labor',
                    style: GoogleFonts.spaceGrotesk(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: laborController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      hint: 'Descripción de la tarea',
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 15),
                  Text(
                    'Ubicación (Opcional)',
                    style: GoogleFonts.spaceGrotesk(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: ubicacionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(hint: 'Ej: Bloque A'),
                  ),

                  if (existingTask == null) ...[
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Crear Orden de Trabajo',
                        style: TextStyle(color: Colors.white),
                      ),
                      value: crearOT,
                      activeColor: primaryColor,
                      checkColor: backgroundDark,
                      onChanged: (val) => setState(() => crearOT = val!),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'CANCELAR',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: backgroundDark,
                ),
                onPressed: () async {
                  if (selectedEmployee == null ||
                      laborController.text.isEmpty) {
                    return;
                  }

                  String? error;
                  final provider = context.read<ProgramacionProvider>();

                  if (existingTask != null) {
                    // Update Logic
                    final empleadoBackendId = selectedEmployee!.id;
                    error = await provider.updateProgramacion(
                      id: existingTask.id,
                      fecha: selectedDate,
                      empleadoId: empleadoBackendId,
                      vehiculoId: selectedVehicle?.id,
                      labor: laborController.text,
                      ubicacion: ubicacionController.text,
                    );
                  } else {
                    // Create Logic
                    if (isMultiDay && selectedWeekDays.isNotEmpty) {
                      final startOfWeek = selectedDate.subtract(
                        Duration(days: selectedDate.weekday - 1),
                      );
                      final dates = selectedWeekDays
                          .map((wd) => startOfWeek.add(Duration(days: wd - 1)))
                          .toList();
                      final empleadoBackendId = selectedEmployee!.id;
                      error = await provider.createProgramacionMultiple(
                        fechas: dates,
                        empleadoId: empleadoBackendId,
                        vehiculoId: selectedVehicle?.id,
                        labor: laborController.text,
                        ubicacion: ubicacionController.text,
                        crearOT: crearOT,
                      );
                    } else {
                      final empleadoBackendId = selectedEmployee!.id;
                      error = await provider.createProgramacion(
                        fecha: selectedDate,
                        empleadoId: empleadoBackendId,
                        vehiculoId: selectedVehicle?.id,
                        labor: laborController.text,
                        ubicacion: ubicacionController.text,
                        crearOT: crearOT,
                      );
                    }
                  }

                  if (context.mounted) {
                    if (error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            existingTask != null
                                ? 'Tarea actualizada'
                                : 'Tarea creada correctamente',
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $error'),
                          backgroundColor: stateIssue,
                        ),
                      );
                    }
                  }
                },
                child: const Text('GUARDAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportNovedadDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const IncidentReportScreen()),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: primaryColor),
      ),
    );
  }
}
