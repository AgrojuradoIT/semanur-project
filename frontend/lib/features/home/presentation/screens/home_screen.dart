import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/features/home/presentation/screens/home_dashboard.dart';
import 'package:frontend/features/home/presentation/screens/home_web_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Si estamos en WEB o el ancho de pantalla es mayor a 800 (tablet/escritorio)
    // mostramos la versión diseñada para pantallas grandes
    if (kIsWeb || MediaQuery.of(context).size.width > 800) {
      return const HomeWebDashboard();
    }
    
    // De lo contrario mostramos la versión móvil actual
    return const HomeDashboard();
  }
}
