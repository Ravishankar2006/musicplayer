import 'package:flutter/material.dart';
import 'package:musicplayer/utils/app_colors.dart';

class MatteContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool elevated;
  final Border? border;

  const MatteContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 16,
    this.elevated = false,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: elevated ? AppColors.elevatedSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.border, width: 0.5),
        boxShadow: elevated
            ? [
                const BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                )
              ]
            : null,
      ),
      child: child,
    );
  }
}
