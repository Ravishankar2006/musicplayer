import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

final isFullScreenProvider = StateNotifierProvider<WindowNotifier, bool>((ref) {
  return WindowNotifier();
});

class WindowNotifier extends StateNotifier<bool> {
  WindowNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    state = await windowManager.isFullScreen();
  }

  Future<void> toggleFullScreen() async {
    bool isFull = await windowManager.isFullScreen();
    await windowManager.setFullScreen(!isFull);
    state = !isFull;
  }
}
