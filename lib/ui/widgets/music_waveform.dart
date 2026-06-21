import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:waveform_visualizer/waveform_visualizer.dart';

class MusicWaveform extends StatefulWidget {
  final bool isPlaying;

  const MusicWaveform({
    super.key,
    required this.isPlaying,
  });

  @override
  State<MusicWaveform> createState() => _MusicWaveformState();
}

class _MusicWaveformState extends State<MusicWaveform> {
  late WaveformController _controller;
  Timer? _fakeTimer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _controller = WaveformController(
      maxDataPoints: 80,
      updateInterval: const Duration(milliseconds: 33),
      smoothingFactor: 0.85,
    );

    _controller.start();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant MusicWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    _fakeTimer?.cancel();

    if (widget.isPlaying) {
      _fakeTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
        final amplitude = 0.18 + (_random.nextDouble() * 0.55);
        _controller.updateAmplitude(amplitude.clamp(0.0, 1.0));
      });
    } else {
      _controller.updateAmplitude(0.05);
    }
  }

  @override
  void dispose() {
    _fakeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: 240,
      child: WaveformWidget(
        controller: _controller,
        height: 54,
        style: WaveformStyle(
          waveColor: const Color(0xFF00E5FF),
          backgroundColor: Colors.transparent,
          waveformStyle: WaveformDrawStyle.bars,
          showGradient: true,
          strokeWidth: 3.0,
          barCount: 28,
          barSpacing: 3.0,
          animationDuration: const Duration(milliseconds: 140),
        ),
      ),
    );
  }
}