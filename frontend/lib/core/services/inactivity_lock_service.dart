import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class InactivityLockService {
  static final InactivityLockService _instance =
      InactivityLockService._internal();
  factory InactivityLockService() => _instance;
  InactivityLockService._internal();

  Timer? _timer;
  bool _enabled = false;
  bool _isHandlingTimeout = false;
  Duration _timeout = const Duration(minutes: 15);
  Future<void> Function()? _onTimeout;

  bool get enabled => _enabled;
  Duration get timeout => _timeout;

  void configureFromEnv() {
    _enabled =
        (dotenv.env['ENABLE_INACTIVITY_LOCK'] ?? 'false').toLowerCase() ==
        'true';

    final minutes = int.tryParse(dotenv.env['INACTIVITY_LOCK_MINUTES'] ?? '');
    if (minutes != null && minutes > 0) {
      _timeout = Duration(minutes: minutes);
    }

    debugPrint(
      'InactivityLockService: enabled=$_enabled timeout=${_timeout.inMinutes}m',
    );
  }

  void start({required Future<void> Function() onTimeout}) {
    _onTimeout = onTimeout;
    if (!_enabled) return;
    _resetTimer();
  }

  void registerActivity() {
    if (!_enabled) return;
    _resetTimer();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () async {
      if (_isHandlingTimeout) return;
      if (_onTimeout == null) return;

      _isHandlingTimeout = true;
      try {
        await _onTimeout!.call();
      } finally {
        _isHandlingTimeout = false;
      }
    });
  }
}
