import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:musicplayer/utils/app_theme.dart';

class AppGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;

  const AppGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 20,
    this.blur = 15,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      padding: padding,
      borderRadius: BorderRadius.circular(borderRadius),
      blur: blur,
      color: AppTheme.glassColor,
      borderColor: AppTheme.glassBorder,
      borderWidth: 1.0,
      elevation: 10,
      shadowColor: Colors.black.withAlpha((0.5 * 255).round()),
      child: child,
    );
  }
}
