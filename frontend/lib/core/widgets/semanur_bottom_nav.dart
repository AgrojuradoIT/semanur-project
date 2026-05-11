import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/profile/presentation/screens/profile_screen.dart';

enum SemanurNavItem { home, fuel, profile }

class SemanurBottomNav extends StatefulWidget {
  final SemanurNavItem current;
  final bool showCenterGap;

  const SemanurBottomNav({
    super.key,
    required this.current,
    this.showCenterGap = false,
  });

  @override
  State<SemanurBottomNav> createState() => _SemanurBottomNavState();
}

class _SemanurBottomNavState extends State<SemanurBottomNav> {
  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0A0A0A).withValues(alpha: 0.9);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.only(
            left: 32,
            right: 32,
            top: 12,
            bottom: bottomPadding > 0 ? bottomPadding : 24,
          ),
          child: Row(
            mainAxisAlignment: widget.showCenterGap 
                ? MainAxisAlignment.spaceAround 
                : MainAxisAlignment.spaceEvenly,
            children: [
              _navItem(
                context,
                SemanurNavItem.home,
                Icons.grid_view_rounded,
                'Panel',
              ),
              if (widget.showCenterGap) const SizedBox(width: 80),
              _navItem(
                context,
                SemanurNavItem.profile,
                Icons.account_circle_outlined,
                'Perfil',
              ),
            ],
          ),
        ),
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
    final color = isActive ? AppTheme.primaryYellow : Colors.grey.shade500;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context, item),
        borderRadius: BorderRadius.circular(12),
        highlightColor: Colors.transparent,
        splashColor: AppTheme.primaryYellow.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, SemanurNavItem target) {
    if (target == widget.current && _isOnTargetScreen(context, target)) return;

    switch (target) {
      case SemanurNavItem.home:
        _replaceTo(context, const HomeScreen());
        break;
      case SemanurNavItem.fuel:
        break;
      case SemanurNavItem.profile:
        _replaceTo(context, const ProfileScreen());
        break;
    }
  }

  bool _isOnTargetScreen(BuildContext context, SemanurNavItem target) {
    switch (target) {
      case SemanurNavItem.home:
        return context.findAncestorWidgetOfExactType<HomeScreen>() != null;
      case SemanurNavItem.fuel:
        return widget.current == SemanurNavItem.fuel;
      case SemanurNavItem.profile:
        return context.findAncestorWidgetOfExactType<ProfileScreen>() != null;
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
