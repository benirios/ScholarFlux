import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// A frosted-glass container inspired by Apple's Liquid Glass design.
///
/// Applies a backdrop blur + translucent fill + specular highlight edge +
/// subtle border for depth.  Set [showHighlight] to false to omit the top
/// specular edge (useful for compact/inline variants).
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? fillColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showHighlight;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 20,
    this.blurSigma = 24,
    this.fillColor,
    this.onTap,
    this.onLongPress,
    this.showHighlight = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (fillColor ?? AppColors.glassFill).withValues(alpha: 0.12),
                (fillColor ?? AppColors.glassFill).withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHighlight)
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(
                    horizontal: borderRadius * 0.6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        AppColors.glassHighlight,
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null || onLongPress != null) {
      content = GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      );
    }

    return content;
  }
}
