import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/services/notification_service.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/providers/user_provider.dart';
import 'package:frontend/features/auth/data/repositories/user_repository.dart';
import 'package:frontend/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:frontend/features/inventory/data/repositories/movement_repository.dart';
import 'package:frontend/features/inventory/presentation/providers/movement_provider.dart';
import 'package:frontend/features/inventory/data/repositories/loan_repository.dart';
import 'package:frontend/features/inventory/presentation/providers/loan_provider.dart';
import 'package:frontend/features/fleet/data/repositories/fuel_repository.dart';
import 'package:frontend/features/fleet/presentation/providers/fuel_provider.dart';
import 'package:frontend/features/fleet/data/repositories/hour_meter_repository.dart';
import 'package:frontend/features/fleet/presentation/providers/hour_meter_provider.dart';
import 'package:frontend/features/fleet/data/repositories/checklist_repository.dart';
import 'package:frontend/features/fleet/presentation/providers/checklist_provider.dart';
import 'package:frontend/features/inventory/data/repositories/inventory_repository.dart';
import 'package:frontend/features/inventory/presentation/providers/inventory_provider.dart';
import 'package:frontend/features/workshop/data/repositories/workshop_repository.dart';
import 'package:frontend/features/workshop/presentation/providers/workshop_provider.dart';
import 'package:frontend/features/workshop/presentation/providers/session_provider.dart';
import 'package:frontend/features/fleet/data/repositories/fleet_repository.dart';
import 'package:frontend/features/fleet/presentation/providers/fleet_provider.dart';
import 'package:frontend/features/analytics/presentation/providers/analytics_provider.dart';
import 'package:frontend/core/providers/sync_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await NotificationService().init();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.red.shade900,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: Colors.yellow, size: 50),
              const SizedBox(height: 10),
              const Text(
                'CRITICAL UI ERROR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                details.exception.toString(),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                details.stack.toString(),
                style: const TextStyle(color: Colors.white30, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final apiClient = ApiClient(
    onUnauthorized: () {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    },
  );

  final authRepository = AuthRepository(apiClient);
  final inventoryRepository = InventoryRepository(apiClient);
  final workshopRepository = WorkOrderRepository(apiClient);
  final fleetRepository = FleetRepository(apiClient);
  final movementRepository = MovementRepository(apiClient);
  final loanRepository = LoanRepository(apiClient);
  final fuelRepository = FuelRepository(apiClient);
  final horometroRepository = HorometroRepository(apiClient);
  final userRepository = UserRepository(apiClient);
  final checklistRepository = ChecklistRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepository)),
        ChangeNotifierProvider(create: (_) => SyncProvider(apiClient)),
        ChangeNotifierProxyProvider<NotificationProvider, InventoryProvider>(
          create: (ctx) => InventoryProvider(
            inventoryRepository,
            ctx.read<NotificationProvider>(),
          ),
          update: (_, notif, prev) =>
              prev ?? InventoryProvider(inventoryRepository, notif),
        ),
        ChangeNotifierProxyProvider<SyncProvider, WorkshopProvider>(
          create: (ctx) =>
              WorkshopProvider(workshopRepository, ctx.read<SyncProvider>()),
          update: (_, sync, prev) =>
              prev ?? WorkshopProvider(workshopRepository, sync),
        ),
        ChangeNotifierProvider(create: (_) => FleetProvider(fleetRepository)),
        ChangeNotifierProxyProvider<SyncProvider, MovementProvider>(
          create: (ctx) =>
              MovementProvider(movementRepository, ctx.read<SyncProvider>()),
          update: (_, sync, prev) =>
              prev ?? MovementProvider(movementRepository, sync),
        ),
        ChangeNotifierProvider(create: (_) => LoanProvider(loanRepository)),
        ChangeNotifierProxyProvider<SyncProvider, FuelProvider>(
          create: (ctx) =>
              FuelProvider(fuelRepository, ctx.read<SyncProvider>()),
          update: (_, sync, prev) => prev ?? FuelProvider(fuelRepository, sync),
        ),
        ChangeNotifierProvider(
          create: (_) => HorometroProvider(horometroRepository),
        ),
        ChangeNotifierProvider(create: (_) => UserProvider(userRepository)),
        ChangeNotifierProxyProvider<SyncProvider, ChecklistProvider>(
          create: (ctx) =>
              ChecklistProvider(checklistRepository, ctx.read<SyncProvider>()),
          update: (_, sync, prev) =>
              prev ?? ChecklistProvider(checklistRepository, sync),
        ),
        ChangeNotifierProxyProvider<SyncProvider, SessionProvider>(
          create: (ctx) => SessionProvider(
            apiClient,
            syncProvider: ctx.read<SyncProvider>(),
          ),
          update: (_, sync, prev) =>
              prev ?? SessionProvider(apiClient, syncProvider: sync),
        ),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(apiClient)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Semanur HUB app',
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}
