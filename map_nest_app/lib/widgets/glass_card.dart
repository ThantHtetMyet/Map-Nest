import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        color: backgroundColor ?? 
          (isDark 
            ? Colors.black.withOpacity(0.4)
            : Colors.white.withOpacity(0.85)), // More opaque in light mode for visibility
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.3)
              : Colors.black.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.6)
                : Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          // Additional shadow for better depth in light mode
          if (!isDark)
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
        ],
      ),
      child: child,
    );
  }
}

