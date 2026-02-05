import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const CustomLoader({super.key, this.size = 50.0, this.color, this.message});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: (widget.color ?? AppTheme.primaryYellow)
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (widget.color ?? AppTheme.primaryYellow),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.bolt, // Icono dinámico (ej. rayo/energía)
                        color: widget.color ?? AppTheme.primaryYellow,
                        size: widget.size * 0.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: TextStyle(
                color: widget.color ?? AppTheme.textGray,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
