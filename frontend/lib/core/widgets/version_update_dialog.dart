import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:frontend/core/services/version_service.dart';
import 'package:frontend/core/theme/app_theme.dart';

/// Dialog que informa al usuario sobre una nueva versión disponible
/// y permite descargar e instalar el APK.
class VersionUpdateDialog extends StatefulWidget {
  final AppVersionInfo versionInfo;
  final String currentVersion;

  const VersionUpdateDialog({
    super.key,
    required this.versionInfo,
    required this.currentVersion,
  });

  @override
  State<VersionUpdateDialog> createState() => _VersionUpdateDialogState();
}

class _VersionUpdateDialogState extends State<VersionUpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _error;

  Future<void> _downloadAndInstall() async {
    if (widget.versionInfo.downloadUrl.isEmpty) {
      setState(() => _error = 'URL de descarga no disponible');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _error = null;
    });

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'semanur-${widget.versionInfo.latestVersion}.apk';
      final filePath = '${dir.path}/$fileName';

      await Dio().download(
        widget.versionInfo.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (!mounted) return;

      // Abrir el APK para instalar
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        setState(() => _error = 'No se pudo abrir el archivo: ${result.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error descargando: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = widget.versionInfo.releaseNotes.isNotEmpty
        ? widget.versionInfo.releaseNotes
        : 'Mejoras generales y corrección de errores.';

    return PopScope(
      canPop: !widget.versionInfo.forceUpdate,
      child: Dialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryYellow.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.system_update,
                color: AppTheme.primaryYellow,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              'Nueva versión disponible',
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Versiones
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'v${widget.currentVersion}',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: AppTheme.textGray, size: 16),
                const SizedBox(width: 8),
                Text(
                  'v${widget.versionInfo.latestVersion}',
                  style: const TextStyle(
                    color: AppTheme.primaryYellow,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notas de versión
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novedades:',
                    style: GoogleFonts.oswald(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes,
                    style: const TextStyle(
                      color: AppTheme.textGray,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Error message
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

            // Download progress
            if (_isDownloading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _downloadProgress,
                    backgroundColor: AppTheme.surfaceDark2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryYellow,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: AppTheme.primaryYellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Buttons
            Row(
              children: [
                if (!widget.versionInfo.forceUpdate && !_isDownloading)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.surfaceDark2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'DESPUÉS',
                        style: TextStyle(color: AppTheme.textGray),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _downloadAndInstall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.surfaceDark,
                              ),
                            ),
                          )
                        : Text(
                            widget.versionInfo.forceUpdate
                                ? 'ACTUALIZAR AHORA'
                                : 'DESCARGAR',
                            style: GoogleFonts.oswald(
                              color: AppTheme.surfaceDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}
