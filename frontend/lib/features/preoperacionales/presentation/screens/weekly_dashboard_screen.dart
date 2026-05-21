import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:frontend/features/preoperacionales/data/models/preoperacional_semana_model.dart';
import 'package:frontend/features/preoperacionales/presentation/providers/preoperacional_provider.dart';

class WeeklyDashboardScreen extends StatefulWidget {
  final int semanaId;
  final String vehiculoPlaca;
  final String? semanaRange;

  const WeeklyDashboardScreen({
    super.key,
    required this.semanaId,
    required this.vehiculoPlaca,
    this.semanaRange,
  });

  @override
  State<WeeklyDashboardScreen> createState() => _WeeklyDashboardScreenState();
}

class _WeeklyDashboardScreenState extends State<WeeklyDashboardScreen> {
  bool _isInitialized = false;

  static const _dayLabels = ['LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM'];
  static const _dayKeys = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    final provider = context.read<PreoperacionalProvider>();
    await provider.loadSemana(widget.semanaId);
    if (mounted) {
      _isInitialized = true;
    }
  }

  PreoperacionalSemana? get _semana {
    final provider = context.read<PreoperacionalProvider>();
    return provider.currentSemana;
  }

  PreoperacionalDailyForm? _getDailyForm(String diaKey) {
    return _semana?.dailyForms.firstWhere(
      (df) => df.diaSemana.toLowerCase() == diaKey.toLowerCase(),
      orElse: () => PreoperacionalDailyForm(
        id: 0,
        semanaId: widget.semanaId,
        diaSemana: diaKey,
        fecha: DateTime.now(),
        completado: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  bool _isToday(int weekdayIndex) {
    return DateTime.now().weekday - 1 == weekdayIndex;
  }

  int get _completedDays {
    return _semana?.dailyForms.where((df) => df.completado).length ?? 0;
  }

  bool _hasCriticalFailures(String diaKey) {
    final form = _getDailyForm(diaKey);
    if (form == null || !form.completado || form.responses == null) return false;
    return form.responses!.any((r) => r.isFailed);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PreoperacionalProvider>();

    if (provider.isLoading && !_isInitialized) {
      return SemanurScaffold(
        showBottomNav: false,
        appBar: AppBar(title: const Text('CARGANDO...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return SemanurScaffold(
      showBottomNav: false,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.vehiculoPlaca,
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            if (widget.semanaRange != null)
              Text(
                widget.semanaRange!,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: AppTheme.textGray,
                ),
              ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Week summary
          _buildWeekSummary(),
          const SizedBox(height: 24),

          // Day pills row
          _buildDayPills(),
          const SizedBox(height: 24),

          // Completed days list
          Text(
            'DÍAS COMPLETADOS',
            style: GoogleFonts.oswald(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildCompletedDaysList(),

          const SizedBox(height: 16),

          // Button for incomplete days
          if (_completedDays < 7) _buildCompletePendingButton(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWeekSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppTheme.primaryYellow,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUMEN SEMANAL',
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textGray,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.oswald(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: '$_completedDays'),
                      TextSpan(
                        text: '/7',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textGray,
                        ),
                      ),
                      TextSpan(
                        text: ' días',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: AppTheme.textGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Circular progress
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: _completedDays / 7,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.surfaceDark2,
                    valueColor: AlwaysStoppedAnimation(
                      _completedDays >= 7 ? Colors.green : AppTheme.primaryYellow,
                    ),
                  ),
                ),
                Text(
                  '${((_completedDays / 7) * 100).toInt()}%',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPills() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(7, (index) {
          final diaKey = _dayKeys[index];
          final label = _dayLabels[index];
          final form = _getDailyForm(diaKey);
          final isToday = _isToday(index);
          final isCompleted = form?.completado ?? false;
          final hasCritical = _hasCriticalFailures(diaKey);

          Color bgColor;
          Color borderColor;
          Color textColor;
          IconData? icon;

          if (isCompleted) {
            if (hasCritical) {
              bgColor = Colors.red.withValues(alpha: 0.15);
              borderColor = Colors.red;
              textColor = Colors.red;
              icon = Icons.warning_rounded;
            } else {
              bgColor = Colors.green.withValues(alpha: 0.15);
              borderColor = Colors.green;
              textColor = Colors.green;
              icon = Icons.check_circle_rounded;
            }
          } else if (isToday) {
            bgColor = AppTheme.primaryYellow.withValues(alpha: 0.1);
            borderColor = AppTheme.primaryYellow;
            textColor = AppTheme.primaryYellow;
          } else {
            bgColor = AppTheme.surfaceDark2;
            borderColor = AppTheme.surfaceDark2;
            textColor = AppTheme.textGray;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: isCompleted
                  ? () => _showDayReview(diaKey, form)
                  : null,
              child: Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: isToday ? 2 : 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.oswald(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (icon != null)
                      Icon(icon, size: 16, color: textColor)
                    else
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: textColor, width: 1.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildCompletedDaysList() {
    final semana = _semana;
    if (semana == null || semana.dailyForms.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No hay días completados aún',
              style: TextStyle(color: AppTheme.textGray),
            ),
          ),
        ),
      ];
    }

    return semana.dailyForms
        .where((df) => df.completado)
        .map((df) => _buildDayCard(df))
        .toList();
  }

  Widget _buildDayCard(PreoperacionalDailyForm form) {
    final hasCritical =
        form.responses?.any((r) => r.isFailed) ?? false;
    final responseCount = form.responses?.length ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCritical
              ? Colors.red.withValues(alpha: 0.3)
              : AppTheme.surfaceDark2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasCritical
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasCritical ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: hasCritical ? Colors.red : Colors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  form.diaSemana.toUpperCase(),
                  style: GoogleFonts.oswald(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$responseCount items registrados',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: AppTheme.textGray,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.textGray,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePendingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate back to vehicle selection to pick a vehicle for today
          Navigator.pop(context);
        },
        icon: const Icon(Icons.edit_calendar),
        label: Text(
          'COMPLETAR DÍA PENDIENTE',
          style: GoogleFonts.oswald(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  void _showDayReview(String diaKey, PreoperacionalDailyForm? form) {
    if (form == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: Text(
          diaKey.toUpperCase(),
          style: GoogleFonts.oswald(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (form.responses != null)
                ...form.responses!.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: r.isOk
                                ? Colors.green
                                : r.isFailed
                                    ? Colors.red
                                    : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Item #${r.itemId}: ${r.estado}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              if (form.observacionesDia != null &&
                  form.observacionesDia!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: AppTheme.surfaceDark2),
                const SizedBox(height: 8),
                Text(
                  'Observaciones:',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  form.observacionesDia!,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }
}
