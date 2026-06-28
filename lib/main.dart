import 'dart:ffi';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musicplayer/providers/music_providers.dart';
import 'package:musicplayer/services/audio_handler.dart';
import 'package:musicplayer/utils/app_theme.dart';
import 'package:musicplayer/ui/screens/home_screen.dart';
import 'package:musicplayer/services/database_service.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

// LC_NUMERIC is typically 1 on Linux (glibc)
const int lcNumeric = 1;

void setupLinuxLocale() {
  if (Platform.isLinux) {
    try {
      final libc = DynamicLibrary.process();
      final setlocale = libc.lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)
      >('setlocale');

      final cLocale = 'C'.toNativeUtf8();
      setlocale(lcNumeric, cLocale);
      malloc.free(cLocale);
    } catch (e) {
      // Ignore if setlocale is not found or fails
    }
  }
}

void main() async {
  setupLinuxLocale();
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  
  // Initialize Media Kit for robust Linux/Windows playback
  JustAudioMediaKit.ensureInitialized(
    linux: true,
    windows: true,
    android: false, // Keep native just_audio for Android
  );
  
  // Initialize Audio Service
  globalAudioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.musicplayer.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    ),
  );
  
  await DatabaseService.instance.init();
  runApp(
    const ProviderScope(
      child: MusicPlayerApp(),
    ),
  );
}

class MusicPlayerApp extends ConsumerWidget {
  const MusicPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Premium Music',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
