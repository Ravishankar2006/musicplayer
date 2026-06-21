import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import '../../services/waveform_service.dart';

class SongWaveform extends StatefulWidget {
  final String audioPath;

  const SongWaveform({
    super.key,
    required this.audioPath,
  });

  @override
  State<SongWaveform> createState() => _SongWaveformState();
}

class _SongWaveformState extends State<SongWaveform> {
  final WaveformService _waveformService = WaveformService();
  Waveform? waveform;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  Future<void> _loadWaveform() async {
    final result = await _waveformService.extractWaveform(widget.audioPath);
    if (!mounted) return;

    setState(() {
      waveform = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (waveform == null) {
      return const SizedBox(
        height: 56,
        child: Center(child: Text('Waveform unavailable')),
      );
    }

    return SizedBox(
      height: 56,
      child: CustomPaint(
        painter: _WaveformPainter(waveform!),
        size: const Size(double.infinity, 56),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Waveform waveform;

  _WaveformPainter(this.waveform);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withAlpha((0.5 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    final step = waveform.length / size.width;

    for (var i = 0; i < size.width; i++) {
      final index = (i * step).floor();
      final sample = waveform.getPixelMax(index).toDouble();
      final y = (1 - (sample / 128.0)) * size.height / 2; // Assuming 8-bit or similar normalization
      if (i == 0) {
        path.moveTo(i.toDouble(), y);
      } else {
        path.lineTo(i.toDouble(), y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform;
  }
}