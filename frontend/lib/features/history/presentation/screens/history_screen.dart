import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/history/data/models/history_item.dart';
import 'package:frontend/features/history/presentation/providers/history_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedModule = 'Todos';
  String _selectedUser = 'Todos';
  String _selectedAction = 'Todas';
  String _selectedDateRange = '30d';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().fetchAllHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final allItems = historyProvider.historyItems;
    final items = _filterItems(allItems);

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: Text(
          'CENTRO DE ACTIVIDAD',
          style: GoogleFonts.oswald(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => historyProvider.fetchAllHistory(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(allItems, items),
          _buildSearchBar(),
          _buildModuleFilters(),
          _buildAdvancedFilters(allItems),
          Expanded(
            child: historyProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(items[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<HistoryItem> _filterItems(List<HistoryItem> allItems) {
    final now = DateTime.now();
    DateTime? from;
    if (_selectedDateRange == '7d') {
      from = now.subtract(const Duration(days: 7));
    } else if (_selectedDateRange == '30d') {
      from = now.subtract(const Duration(days: 30));
    }

    return allItems.where((item) {
      final matchesModule =
          _selectedModule == 'Todos' || item.module == _selectedModule;

      final matchesUser = _selectedUser == 'Todos' || item.user == _selectedUser;

      final matchesAction =
          _selectedAction == 'Todas' ||
          _actionLabel(item.actionType) == _selectedAction;

      final matchesDate = from == null || item.timestamp.isAfter(from);

      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.user.toLowerCase().contains(query) ||
          (item.reference ?? '').toLowerCase().contains(query);

      return matchesModule &&
          matchesUser &&
          matchesAction &&
          matchesDate &&
          matchesSearch;
    }).toList();
  }

  Widget _buildSummary(List<HistoryItem> allItems, List<HistoryItem> filtered) {
    final uniqueUsers = allItems.map((e) => e.user).toSet().length;
    final lastTimestamp = allItems.isNotEmpty ? allItems.first.timestamp : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _summaryPill('Total', '${allItems.length}'),
          _summaryPill('Filtrado', '${filtered.length}'),
          _summaryPill('Usuarios', '$uniqueUsers'),
          _summaryPill(
            'Ult. actividad',
            lastTimestamp != null
                ? DateFormat('dd/MM HH:mm', 'es_CO').format(lastTimestamp)
                : '--',
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppTheme.textGray),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleFilters() {
    final modules = ['Todos', 'Inventario', 'Taller', 'Flota'];
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: modules.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final module = modules[index];
          final isSelected = _selectedModule == module;
          return ChoiceChip(
            label: Text(module),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedModule = module),
            backgroundColor: AppTheme.surfaceDark,
            selectedColor: AppTheme.primaryYellow,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryYellow
                    : AppTheme.surfaceDark2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedFilters(List<HistoryItem> allItems) {
    final users = <String>{'Todos', ...allItems.map((e) => e.user)}.toList()
      ..sort();
    final actions = ['Todas', 'Crear', 'Actualizar', 'Eliminar', 'Estado', 'Sesion'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Usuario',
                  value: users.contains(_selectedUser) ? _selectedUser : 'Todos',
                  items: users,
                  onChanged: (v) => setState(() => _selectedUser = v ?? 'Todos'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  label: 'Accion',
                  value: _selectedAction,
                  items: actions,
                  onChanged: (v) => setState(() => _selectedAction = v ?? 'Todas'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Rango:',
                style: TextStyle(color: AppTheme.textGray, fontSize: 12),
              ),
              const SizedBox(width: 8),
              _dateChip('7d'),
              const SizedBox(width: 6),
              _dateChip('30d'),
              const SizedBox(width: 6),
              _dateChip('Todo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: AppTheme.surfaceDark,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          hint: Text(label, style: const TextStyle(color: AppTheme.textGray)),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dateChip(String label) {
    final value = label == 'Todo' ? 'all' : label;
    final selected = _selectedDateRange == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedDateRange = value),
      backgroundColor: AppTheme.surfaceDark,
      selectedColor: AppTheme.primaryYellow,
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontSize: 12,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? AppTheme.primaryYellow : AppTheme.surfaceDark2,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por usuario, referencia, accion...',
          hintStyle: const TextStyle(color: Colors.white30),
          prefixIcon: const Icon(Icons.search, color: Colors.white30),
          filled: true,
          fillColor: AppTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 24),
        ),
        title: Text(
          item.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _metaTag(Icons.person_outline, item.user),
                _metaTag(
                  Icons.access_time,
                  DateFormat('MMM d, h:mm a', 'es_CO').format(item.timestamp),
                ),
                if (item.reference != null)
                  _metaTag(Icons.tag, item.reference!),
                _metaTag(Icons.bolt, _actionLabel(item.actionType)),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.module,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ),
      ),
    );
  }

  Widget _metaTag(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textGray),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textGray, fontSize: 11),
        ),
      ],
    );
  }

  String _actionLabel(HistoryActionType actionType) {
    switch (actionType) {
      case HistoryActionType.create:
        return 'Crear';
      case HistoryActionType.update:
        return 'Actualizar';
      case HistoryActionType.delete:
        return 'Eliminar';
      case HistoryActionType.status:
        return 'Estado';
      case HistoryActionType.session:
        return 'Sesion';
      case HistoryActionType.unknown:
        return 'Otro';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 60,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay registros para los filtros seleccionados',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
