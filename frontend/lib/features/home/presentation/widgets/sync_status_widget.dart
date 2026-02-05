import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/core/theme/app_theme.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = context.watch<SyncProvider>();

    IconData icon;
    Color color;
    String statusText;

    if (syncProvider.status == SyncStatus.syncing) {
      icon = Icons.cloud_sync;
      color = Colors.blue;
      statusText = 'Sincronizando...';
    } else if (syncProvider.status == SyncStatus.offline) {
      icon = Icons.cloud_off;
      color = Colors.orange;
      statusText = 'Offline';
    } else {
      icon = Icons.cloud_done;
      color = Colors.green;
      statusText = 'Online';
    }

    if (syncProvider.pendingCount > 0) {
      color = Colors.orange; // Advertencia si hay pendientes
    }

    return GestureDetector(
      onTap: () => _showSyncDetails(context, syncProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              syncProvider.pendingCount > 0
                  ? '${syncProvider.pendingCount} Pendientes'
                  : statusText,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncDetails(BuildContext context, SyncProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark2,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ESTADO DE SINCRONIZACIÓN',
              style: GoogleFonts.oswald(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 25),
            _buildDetailRow(
              'Conexión',
              provider.status == SyncStatus.offline
                  ? 'Sin Internet'
                  : 'Conectado',
              provider.status == SyncStatus.offline
                  ? Icons.wifi_off
                  : Icons.wifi,
              provider.status == SyncStatus.offline ? Colors.red : Colors.green,
            ),
            _buildDetailRow(
              'Datos pendientes por subir',
              '${provider.pendingCount} registros',
              Icons.upload_file,
              provider.pendingCount > 0 ? Colors.orange : Colors.green,
            ),
            _buildDetailRow(
              'Sincronización inicial',
              provider.isInitialSyncCompleted
                  ? 'Completada'
                  : (provider.lastSyncError != null ? 'Error' : 'Pendiente'),
              Icons.download_done,
              provider.isInitialSyncCompleted
                  ? Colors.green
                  : (provider.lastSyncError != null ? Colors.red : Colors.grey),
            ),
            if (provider.lastSyncError != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Error: ${provider.lastSyncError}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            if (provider.status != SyncStatus.offline &&
                provider.pendingCount > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    provider.syncNow();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Forzar Sincronización'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryYellow,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
}
