import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/fleet/presentation/screens/add_fuel_screen.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';

enum SemanurNavItem { home, fuel, profile }

class SemanurBottomNav extends StatelessWidget {
  final SemanurNavItem current;
  final bool showCenterGap;

  const SemanurBottomNav({
    super.key,
    required this.current,
    this.showCenterGap = false,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    final items = <Widget>[
      _navItem(context, SemanurNavItem.home, Icons.dashboard_rounded, 'Inicio'),
      if (user != null && user.canAccessModule('combustible'))
        _navItem(
          context,
          SemanurNavItem.fuel,
          Icons.local_gas_station,
          'Abastecimiento',
        ),
      if (showCenterGap) const SizedBox(width: 40),
      _navItem(context, SemanurNavItem.profile, Icons.person_outlined, 'Perfil'),
    ];

    return Container(
      height: 90,
      padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppTheme.surfaceDark2)),
      ),
      child: Row(
        mainAxisAlignment: showCenterGap
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.spaceEvenly,
        children: items,
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    SemanurNavItem item,
    IconData icon,
    String label,
  ) {
    final bool isActive = _isOnTargetScreen(context, item);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTap(context, item),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppTheme.primaryYellow.withValues(alpha: 0.12),
          highlightColor: AppTheme.primaryYellow.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.primaryYellow : AppTheme.textGray,
                  size: 26,
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppTheme.textGray,
                    fontSize: 10,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, SemanurNavItem target) {
    if (target == current && _isOnTargetScreen(context, target)) {
      return;
    }

    switch (target) {
      case SemanurNavItem.home:
        _replaceTo(context, const HomeScreen());
        break;
      case SemanurNavItem.profile:
        _replaceTo(context, const ProfileScreen());
        break;
      case SemanurNavItem.fuel:
        _replaceTo(context, const AddFuelScreen());
        break;
    }
  }

  bool _isOnTargetScreen(BuildContext context, SemanurNavItem target) {
    switch (target) {
      case SemanurNavItem.home:
        return context.findAncestorWidgetOfExactType<HomeScreen>() != null;
      case SemanurNavItem.profile:
        return context.findAncestorWidgetOfExactType<ProfileScreen>() != null;
      case SemanurNavItem.fuel:
        return context.findAncestorWidgetOfExactType<AddFuelScreen>() != null;
    }
  }

  void _replaceTo(BuildContext context, Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
