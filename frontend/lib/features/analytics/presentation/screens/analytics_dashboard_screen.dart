import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/custom_loader.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().fetchAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        title: Text(
          'DASHBOARD ANALÍTICO',
          style: GoogleFonts.oswald(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: provider.isLoading
          ? const Center(
              child: CustomLoader(
                message: 'Generando reportes...',
                color: AppTheme.primaryYellow,
              ),
            )
          : provider.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar analítica',
                    style: GoogleFonts.oswald(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textGray),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: provider.fetchAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: provider.fetchAll,
              color: AppTheme.primaryYellow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryGrid(provider.summary),
                    const SizedBox(height: 30),
                    _buildSectionTitle('CONSUMO MENSUAL DE COMBUSTIBLE'),
                    const SizedBox(height: 15),
                    _buildFuelChart(provider.fuelStats),
                    const SizedBox(height: 30),
                    _buildSectionTitle('GASTOS DE MANTENIMIENTO POR VEHÍCULO'),
                    const SizedBox(height: 15),
                    _buildMaintenanceChart(provider.maintenanceStats),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.oswald(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.primaryYellow,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic>? summary) {
    if (summary == null) return const SizedBox.shrink();

    final currencyFormat = NumberFormat.currency(
      symbol: "\$",
      decimalDigits: 0,
    );

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'TOTAL COMBUSTIBLE',
          currencyFormat.format(summary['total_fuel_cost']),
          Icons.local_gas_station,
          Colors.orange,
        ),
        _buildStatCard(
          'TOTAL MANT.',
          currencyFormat.format(summary['total_maintenance_cost']),
          Icons.build,
          Colors.blue,
        ),
        _buildStatCard(
          'VEHÍCULOS',
          summary['vehicle_count'].toString(),
          Icons.local_shipping,
          Colors.green,
        ),
        _buildStatCard(
          'OT ABIERTAS',
          summary['open_orders'].toString(),
          Icons.assignment,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.oswald(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelChart(List<dynamic>? stats) {
    if (stats == null || stats.isEmpty) {
      return _buildEmptyState('No hay datos de combustible disponibles');
    }

    // Safety: ensure values are not all zero to prevent maxY = 0 issues if needed
    // And handle potential string/number mismatch safely
    double maxVal = 0;
    try {
      maxVal = stats
          .map((e) => (num.tryParse(e['cost'].toString()) ?? 0).toDouble())
          .reduce((a, b) => a > b ? a : b);
    } catch (_) {}

    if (maxVal <= 0) maxVal = 1000; // Default fallback to avoid chart crash

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppTheme.surfaceDark2,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${NumberFormat.compact().format(rod.toY)}',
                  const TextStyle(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= stats.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getMonthName(stats[index]['month']),
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: stats.asMap().entries.map((entry) {
            final val = (num.tryParse(entry.value['cost'].toString()) ?? 0)
                .toDouble();
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: val,
                  color: AppTheme.primaryYellow,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMaintenanceChart(List<dynamic>? stats) {
    if (stats == null || stats.isEmpty) {
      return _buildEmptyState('No hay datos de mantenimiento disponibles');
    }

    // Safety: Find max for relative bar calculation
    double maxTotal = 1;
    for (var item in stats) {
      final val = (num.tryParse(item['total_cost'].toString()) ?? 0).toDouble();
      if (val > maxTotal) maxTotal = val;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        children: stats.take(5).map((item) {
          // Limit to top 5 to avoid overflow
          final double total =
              (num.tryParse(item['total_cost'].toString()) ?? 0).toDouble();
          final String placa = item['placa'] ?? 'N/A';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      placa,
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        symbol: "\$",
                        decimalDigits: 0,
                      ).format(total),
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: total / maxTotal,
                    backgroundColor: AppTheme.surfaceDark2,
                    valueColor: const AlwaysStoppedAnimation(Colors.blue),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ... (keep _buildEmptyState and _getMonthName as is)

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: AppTheme.textGray,
            size: 48,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textGray, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }
}
