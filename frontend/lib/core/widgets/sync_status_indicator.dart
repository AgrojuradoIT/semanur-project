import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/providers/sync_provider.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (syncProvider.isProcessing) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        if (syncProvider.pendingCount > 0) {
          return IconButton(
            tooltip: 'Sincronizar ${syncProvider.pendingCount} pendientes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Iniciando sincronización manual...'),
                ),
              );
              syncProvider.syncNow();
            },
            icon: Stack(
              children: [
                Icon(
                  syncProvider.status == SyncStatus.offline
                      ? Icons.cloud_off
                      : Icons.cloud_upload,
                  color: syncProvider.status == SyncStatus.offline
                      ? Colors.orange
                      : Colors.white,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '${syncProvider.pendingCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Si todo está sincronizado y online, no mostramos nada (o un check opcional)
        return const SizedBox.shrink();
      },
    );
  }
}
