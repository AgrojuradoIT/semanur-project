import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utilidad para debounce de operaciones (ej: búsquedas)
class Debouncer {
  Debouncer({this.milliseconds = 500});

  final int milliseconds;
  Timer? _timer;

  /// Ejecuta la acción después de que haya pasado el tiempo sin nuevas llamadas
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Cancela el timer pendiente
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose del debouncer
  void dispose() {
    cancel();
  }
}
