import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/semanur_scaffold.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/preoperacionales/data/models/preoperacional_template_model.dart';
import 'package:frontend/features/preoperacionales/presentation/providers/preoperacional_provider.dart';

class DailyFormScreen extends StatefulWidget {
  final int vehiculoId;
  final String? templateTipoVehiculo;
  final String vehiculoPlaca;
  final String? vehiculoTipo;

  const DailyFormScreen({
    super.key,
    required this.vehiculoId,
    this.templateTipoVehiculo,
    required this.vehiculoPlaca,
    this.vehiculoTipo,
  });

  @override
  State<DailyFormScreen> createState() => _DailyFormScreenState();
}

class _DailyFormScreenState extends State<DailyFormScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _observacionesController = TextEditingController();

  // Answers: itemId -> estado
  final Map<int, String> _answers = {};
  // Observations for failed items: itemId -> observation text
  final Map<int, TextEditingController> _itemObservations = {};
  // Photos for failed items: itemId -> photo file
  final Map<int, File?> _itemPhotos = {};

  // Section collapse state: sectionId -> isExpanded
  final Map<int, bool> _expandedSections = {};

  bool _isInitialized = false;

  bool get _isAerial =>
      (widget.vehiculoTipo ?? '').toLowerCase().contains('aereo') ||
      (widget.vehiculoTipo ?? '').toLowerCase().contains('aéreo');

  List<String> get _scaleValues =>
      _isAerial ? ['B', 'C', 'NC', 'M', 'NA'] : ['B', 'M'];

  String get _todayLabel {
    final now = DateTime.now();
    const dias = ['LUNES', 'MARTES', 'MIÉRCOLES', 'JUEVES', 'VIERNES', 'SÁBADO', 'DOMINGO'];
    final diaIndex = (now.weekday - 1) % 7;
    return '${dias[diaIndex]} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}';
  }

  String get _diaSemana {
    const dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo'];
    return dias[(DateTime.now().weekday - 1) % 7];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    for (final c in _itemObservations.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    final provider = context.read<PreoperacionalProvider>();
    final auth = context.read<AuthProvider>();
    final inspectorId = auth.user?.id ?? 0;

    // Load templates
    await provider.loadTemplates(tipoVehiculo: widget.templateTipoVehiculo);

    // Load or create semana
    int? templateId;
    if (provider.templates.isNotEmpty) {
      templateId = provider.templates.first.id;
    }
    await provider.loadOrCreateSemana(
      vehiculoId: widget.vehiculoId,
      inspectorId: inspectorId,
      templateId: templateId,
    );

    if (mounted) {
      _isInitialized = true;
      _initializeAnswers();
    }
  }

  void _initializeAnswers() {
    final template = _getActiveTemplate();
    if (template == null) return;

    for (final item in template.items) {
      _answers[item.id] = '';
      if (_itemObservations[item.id] == null) {
        _itemObservations[item.id] = TextEditingController();
      }
      _itemPhotos[item.id] = null;
    }

    // Initialize sections as expanded
    for (final section in template.sections) {
      _expandedSections[section.id] = true;
    }
  }

  PreoperacionalTemplate? _getActiveTemplate() {
    final provider = context.read<PreoperacionalProvider>();
    if (provider.templates.isNotEmpty) return provider.templates.first;
    return provider.currentSemana?.template;
  }

  int get _answeredCount =>
      _answers.values.where((v) => v.isNotEmpty).length;

  int get _totalItems => _answers.length;

  double get _progress =>
      _totalItems > 0 ? _answeredCount / _totalItems : 0.0;

  Future<void> _takePhoto(int itemId) async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (photo != null && mounted) {
      setState(() {
        _itemPhotos[itemId] = File(photo.path);
      });
    }
  }

  Future<void> _submit() async {
    // Validate all items answered
    final unanswered = _answers.entries
        .where((e) => e.value.isEmpty)
        .map((e) => e.key)
        .toList();

    if (unanswered.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Faltan ${unanswered.length} item(s) por responder',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Build respuestas
    final respuestas = _answers.entries.map((e) {
      final itemId = e.key;
      final estado = e.value;
      final obs = _itemObservations[itemId]?.text;
      final photo = _itemPhotos[itemId];

      return {
        'item_id': itemId,
        'estado': estado,
        if (obs != null && obs.isNotEmpty) 'observacion': obs,
        if (photo != null) 'foto_path': photo.path,
      };
    }).toList();

    final provider = context.read<PreoperacionalProvider>();
    final semana = provider.currentSemana;
    if (semana == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay semana activa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline =
        !connectivity.every((r) => r == ConnectivityResult.none);

    if (!mounted) return;

    try {
      if (isOnline) {
        await provider.submitDailyForm(
          semanaId: semana.id,
          diaSemana: _diaSemana,
          respuestas: respuestas,
          observacionesDia: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
        );
      } else {
        await provider.submitDailyFormOffline(
          semanaId: semana.id,
          diaSemana: _diaSemana,
          respuestas: respuestas,
          observacionesDia: _observacionesController.text.isNotEmpty
              ? _observacionesController.text
              : null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline
                ? 'Formulario guardado correctamente'
                : 'Guardado offline - se sincronizará al reconectar',
          ),
          backgroundColor: isOnline ? Colors.green : Colors.orange,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

    if (provider.error != null && !_isInitialized) {
      return SemanurScaffold(
        showBottomNav: false,
        appBar: AppBar(title: const Text('ERROR')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _isInitialized = false;
                    _initialize();
                  },
                  child: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final template = _getActiveTemplate();
    if (template == null) {
      return SemanurScaffold(
        showBottomNav: false,
        appBar: AppBar(title: const Text('SIN PLANTILLA')),
        body: const Center(
          child: Text('No hay plantilla disponible para este vehículo'),
        ),
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
            Text(
              _todayLabel,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: AppTheme.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgress(),

          // Scrollable content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Sections
                ...template.sections.map((section) => _buildSection(section)),

                // Fallback: items without sections
                if (template.items.any((i) => i.sectionId == null))
                  _buildSectionItems(
                    template.items.where((i) => i.sectionId == null).toList(),
                    sectionName: 'GENERAL',
                  ),

                const SizedBox(height: 16),

                // Observaciones del día
                TextFormField(
                  controller: _observacionesController,
                  decoration: const InputDecoration(
                    labelText: 'Observaciones del día',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.comment),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 80), // Space for bottom bar
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: provider.isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _progress >= 1.0 ? Colors.green : AppTheme.primaryYellow,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: provider.isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(
                  _progress >= 1.0
                      ? 'GUARDAR ($_answeredCount/$_totalItems)'
                      : 'GUARDAR ($_answeredCount/$_totalItems)',
                  style: GoogleFonts.oswald(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surfaceDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROGRESO',
                style: GoogleFonts.oswald(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textGray,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$_answeredCount / $_totalItems',
                style: GoogleFonts.oswald(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _progress >= 1.0 ? Colors.green : AppTheme.primaryYellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppTheme.surfaceDark2,
            valueColor: AlwaysStoppedAnimation(
              _progress >= 1.0 ? Colors.green : AppTheme.primaryYellow,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(PreoperacionalTemplateSection section) {
    final isExpanded = _expandedSections[section.id] ?? true;
    final sectionItems = section.items.isNotEmpty
        ? section.items
        : _getActiveTemplate()?.items
                .where((i) => i.sectionId == section.id)
                .toList() ??
            [];
    final answeredInSection =
        sectionItems.where((i) => _answers[i.id]?.isNotEmpty ?? false).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[section.id] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.nombre.toUpperCase(),
                          style: GoogleFonts.oswald(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryYellow,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$answeredInSection / ${sectionItems.length} completados',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: AppTheme.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppTheme.textGray,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: sectionItems
                    .map((item) => _buildItemRow(item))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionItems(
    List<PreoperacionalTemplateItem> items, {
    required String sectionName,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceDark2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionName.toUpperCase(),
              style: GoogleFonts.oswald(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryYellow,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildItemRow(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(PreoperacionalTemplateItem item) {
    final currentStatus = _answers[item.id] ?? '';
    final showObservation =
        currentStatus == 'M' || currentStatus == 'NC' || currentStatus == 'C';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: currentStatus.isEmpty
            ? AppTheme.backgroundDark
            : currentStatus == 'B'
                ? Colors.green.withValues(alpha: 0.05)
                : Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: currentStatus.isEmpty
              ? AppTheme.surfaceDark2
              : currentStatus == 'B'
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.esCritico)
                const Padding(
                  padding: EdgeInsets.only(right: 8, top: 2),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              Expanded(
                child: Text(
                  item.pregunta,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Status toggle
          _buildStatusToggle(item, currentStatus),
          // Observation field (shown when M/NC/C)
          if (showObservation) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _itemObservations[item.id],
              decoration: InputDecoration(
                labelText: item.requiereObservacionSiFalla
                    ? 'Observación (requerida)'
                    : 'Observación (opcional)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            // Photo button
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _takePhoto(item.id),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: Text(
                    _itemPhotos[item.id] != null ? 'Foto tomada' : 'Tomar foto',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryYellow,
                    side: const BorderSide(color: AppTheme.primaryYellow),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                if (_itemPhotos[item.id] != null) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _itemPhotos[item.id]!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusToggle(
    PreoperacionalTemplateItem item,
    String currentStatus,
  ) {
    final scale = item.escalaValores ?? _scaleValues;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: scale.map((value) {
        final isSelected = currentStatus == value;
        final color = _getStatusColor(value);

        return GestureDetector(
          onTap: () {
            setState(() {
              _answers[item.id] = value;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color : AppTheme.surfaceDark2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : AppTheme.surfaceDark2,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              _getStatusLabel(value),
              style: GoogleFonts.oswald(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'B':
        return Colors.green;
      case 'M':
        return Colors.red;
      case 'C':
        return Colors.orange;
      case 'NC':
        return Colors.redAccent;
      case 'NA':
      case 'N/A':
        return Colors.grey;
      default:
        return AppTheme.primaryYellow;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'B':
        return 'BUENO';
      case 'M':
        return 'MALO';
      case 'C':
        return 'CON FALLA';
      case 'NC':
        return 'NO CUMPLE';
      case 'NA':
      case 'N/A':
        return 'N/A';
      default:
        return status;
    }
  }
}
