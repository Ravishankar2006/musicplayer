import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/window_provider.dart';
import 'package:musicplayer/utils/app_colors.dart';

class FullScreenToggle extends ConsumerWidget {
  final Color? color;
  final double size;

  const FullScreenToggle({
    super.key,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show on Desktop
    if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
      return const SizedBox.shrink();
    }

    final isFull = ref.watch(isFullScreenProvider);

    return IconButton(
      tooltip: isFull ? 'Exit full screen' : 'Enter full screen',
      icon: Icon(
        isFull ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
        color: color ?? AppColors.primaryText,
        size: size,
      ),
      onPressed: () => ref.read(isFullScreenProvider.notifier).toggleFullScreen(),
    );
  }
}
