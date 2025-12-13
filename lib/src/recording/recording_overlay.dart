import 'package:audio_play_or_record/src/recording/recording_wave.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RecordingOverlay extends StatelessWidget {
  final Duration duration;
  final Color waveColor;

  const RecordingOverlay({
    super.key,
    required this.duration,
    required this.waveColor,
  });

  String _format(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          RecordingWave(color: waveColor),
          const SizedBox(width: 12),
          Text(
            _format(duration),
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
          const Icon(Icons.delete, color: Colors.red),
        ],
      ),
    );
  }
}
