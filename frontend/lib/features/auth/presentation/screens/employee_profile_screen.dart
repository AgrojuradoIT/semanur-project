import 'package:flutter/material.dart';

import 'package:frontend/features/auth/data/models/empleado_model.dart';
import 'package:google_fonts/google_fonts.dart';

import 'employee_form_screen.dart';

class EmployeeProfileScreen extends StatelessWidget {
  final Empleado employee;

  const EmployeeProfileScreen({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    // Colores basados en el diseño
    final Color primaryYellow = const Color(0xFFFFD600);
    final Color backgroundDark = const Color(0xFF121212);
    final Color surfaceDark = const Color(0xFF1E1E1E);

    return Scaffold(
      backgroundColor: backgroundDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 180),
                    child: Column(
                      children: [
                        _buildProfileHeader(
                          primaryYellow,
                          surfaceDark,
                          backgroundDark,
                        ),
                        _buildRolesSection(primaryYellow, surfaceDark),
                        _buildProfessionalSummary(primaryYellow, surfaceDark),
                        _buildDocumentsSection(
                          context,
                          primaryYellow,
                          surfaceDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildStickyFooter(
            context,
            primaryYellow,
            surfaceDark,
            backgroundDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.white,
          ),
          Text(
            'PERFIL',
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          IconButton(
            onPressed: () {
              // Opciones adicionales
            },
            icon: const Icon(Icons.more_horiz),
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Color primary, Color surface, Color background) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          // Imagen con borde
          Stack(
            children: [
              Container(
                width: 128,
                height: 128,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primary, width: 3),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(
                        employee.fotoUrl ??
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(employee.nombreCompleto.isNotEmpty ? employee.nombreCompleto : 'U')}&background=random&color=fff&size=256',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Status Indicator
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: employee.estado == 'activo' ? primary : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: background, width: 4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nombre y ID
          Text(
            employee.nombreCompleto.toUpperCase(),
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'ID: #${employee.id} • ${employee.cargo ?? "Sin Cargo"}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Stats Row
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem('4.2', 'Años', primary),
                const SizedBox(width: 32),
                _buildStatItem('128', 'Proyectos', primary),
                const SizedBox(width: 32),
                _buildStatItem('98%', 'Asistencia', primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color primary) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRolesSection(Color primary, Color surface) {
    // Convertir cargo a rol principal y dependencias a roles secundarios si hubiera
    final currentRole = employee.cargo ?? 'Sin Rol';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Roles Asignados', Icons.badge, primary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildRoleChip(currentRole, true, primary, surface),
              if (employee.dependencia != null)
                _buildRoleChip(employee.dependencia!, false, primary, surface),
              // Chips inactivos de ejemplo visual
              if (currentRole.toLowerCase() != 'admin')
                _buildRoleChip('Admin', false, primary, surface),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
    String label,
    bool isActive,
    Color primary,
    Color surface,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? primary : surface,
        borderRadius: BorderRadius.circular(30),
        border: isActive ? null : Border.all(color: Colors.white10),
        boxShadow: isActive
            ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 15)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.build
                : Icons.admin_panel_settings, // Icono genérico
            color: isActive ? Colors.black : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? Colors.black : Colors.grey[300],
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalSummary(Color primary, Color surface) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          _buildSectionTitle(
            'Resumen Profesional',
            Icons.person_search,
            primary,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              employee.resumenProfesional != null &&
                      employee.resumenProfesional!.isNotEmpty
                  ? employee.resumenProfesional!
                  : 'Especialista con experiencia en ${employee.dependencia ?? "diversas áreas"}. '
                        'Actualmente desempeñando funciones como ${employee.cargo ?? "colaborador"} '
                        'en Semanur Hub desde ${employee.id < 100 ? "hace varios años" : "recientemente"}.',
              style: GoogleFonts.inter(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(
    BuildContext context,
    Color primary,
    Color surface,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildSectionTitle('Documentos', Icons.folder_shared, primary),
              Text(
                'VER TODOS',
                style: GoogleFonts.inter(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentItem(
            'Licencia de Conducción',
            employee.licenciaConduccion != null
                ? '${employee.categoriaLicencia ?? ""} • Vence: ${employee.vencimientoLicencia?.toString().split(" ")[0] ?? "N/A"}'
                : 'No registrada',
            Icons.card_membership,
            primary,
            surface,
          ),
          const SizedBox(height: 12),
          _buildDocumentItem(
            'Identificación Oficial',
            employee.documento != null
                ? 'C.C. ${employee.documento}'
                : 'No registrada',
            Icons.badge,
            primary,
            surface,
          ),
          if (employee.telefono != null) ...[
            const SizedBox(height: 12),
            _buildDocumentItem(
              'Contacto',
              'Tel: ${employee.telefono}',
              Icons.phone,
              primary,
              surface,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
    String title,
    String subtitle,
    IconData icon,
    Color primary,
    Color surface,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color primary) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyFooter(
    BuildContext context,
    Color primary,
    Color surface,
    Color background,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: background.withValues(alpha: 0.9),
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToEdit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                icon: const Icon(Icons.edit),
                label: Text(
                  'EDITAR PERFIL',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Implementar desactivación
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.white10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(Icons.block, size: 18),
                label: Text(
                  'Desactivar Cuenta',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmployeeFormScreen(employee: employee)),
    );
    // Si se editó algo, podríamos retornar true para recargar la lista
    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}
