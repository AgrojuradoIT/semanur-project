import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/semanur_bottom_nav.dart';
export 'package:frontend/core/widgets/semanur_bottom_nav.dart';

class SemanurScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final FloatingActionButtonAnimator? floatingActionButtonAnimator;
  final bool showBottomNav;
  final SemanurNavItem currentNav;
  final bool showCenterGap;

  const SemanurScaffold({
    super.key,
    this.appBar,
    this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.floatingActionButtonAnimator,
    this.showBottomNav = true,
    this.currentNav = SemanurNavItem.home,
    this.showCenterGap = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButtonAnimator: floatingActionButtonAnimator,
      bottomNavigationBar: showBottomNav
          ? SemanurBottomNav(
              current: currentNav,
              showCenterGap: showCenterGap,
            )
          : null,
    );
  }
}
