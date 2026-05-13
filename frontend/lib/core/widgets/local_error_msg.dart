import 'package:flutter/material.dart';

class LocalErrorMsg extends StatelessWidget {
  final String? error;
  final EdgeInsets padding;

  const LocalErrorMsg({
    super.key,
    required this.error,
    this.padding = const EdgeInsets.only(top: 15),
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Text(
        error!,
        style: const TextStyle(
          color: Color(0xFFEF4444), // stateIssue color
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
