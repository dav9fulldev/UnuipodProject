import 'package:flutter/material.dart';

/// Bouton personnalisé Material 3 avec différents styles
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.filled,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: null,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    final Widget child = icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(text),
            ],
          )
        : Text(text);

    final button = switch (type) {
      ButtonType.filled => FilledButton(
          onPressed: onPressed,
          child: child,
        ),
      ButtonType.elevated => ElevatedButton(
          onPressed: onPressed,
          child: child,
        ),
      ButtonType.outlined => OutlinedButton(
          onPressed: onPressed,
          child: child,
        ),
      ButtonType.text => TextButton(
          onPressed: onPressed,
          child: child,
        ),
    };

    return SizedBox(
      width: width ?? double.infinity,
      height: 48,
      child: button,
    );
  }
}

enum ButtonType {
  filled,
  elevated,
  outlined,
  text,
}
