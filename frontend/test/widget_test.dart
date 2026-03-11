import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/services/inactivity_lock_service.dart';

void main() {
  test('InactivityLockService habilita bloqueo con minutos validos', () {
    dotenv.testLoad(
      fileInput:
          'ENABLE_INACTIVITY_LOCK=true\nINACTIVITY_LOCK_MINUTES=7',
    );

    final service = InactivityLockService();
    service.configureFromEnv();

    expect(service.enabled, isTrue);
    expect(service.timeout.inMinutes, 7);

    service.stop();
  });

  test('InactivityLockService deshabilita bloqueo por variable de entorno', () {
    dotenv.testLoad(
      fileInput:
          'ENABLE_INACTIVITY_LOCK=false\nINACTIVITY_LOCK_MINUTES=20',
    );

    final service = InactivityLockService();
    service.configureFromEnv();

    expect(service.enabled, isFalse);
    expect(service.timeout.inMinutes, 20);

    service.stop();
  });
}
