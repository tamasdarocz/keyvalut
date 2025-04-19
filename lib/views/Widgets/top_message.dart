import 'package:flutter/material.dart';

class TopMessage extends StatelessWidget {
  final String message;
  final Duration duration;
  final Color backgroundColor;
  final Color textColor;

  const TopMessage({
    super.key,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor = Colors.black87,
    this.textColor = Colors.white,
  });

  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: TopMessage(
            message: message,
            duration: duration,
            backgroundColor: backgroundColor,
            textColor: textColor,
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        textAlign: TextAlign.center,
      ),
    );
  }
}