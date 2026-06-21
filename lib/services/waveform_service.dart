import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:just_waveform/just_waveform.dart';

class WaveformService {
  Future<Waveform?> extractWaveform(String audioPath) async {
    final cacheDir = await getTemporaryDirectory();
    final fileName = audioPath.split('/').last.replaceAll('.', '_');
    final waveFile = File('${cacheDir.path}/$fileName.wave');

    final stream = JustWaveform.extract(
      audioInFile: File(audioPath),
      waveOutFile: waveFile,
      zoom: const WaveformZoom.pixelsPerSecond(80),
    );

    Waveform? waveform;

    await for (final progress in stream) {
      if (progress.waveform != null) {
        waveform = progress.waveform;
      }
    }

    return waveform;
  }
}