import 'dart:io';
import 'package:just_waveform/just_waveform.dart';
import 'waveform_cache.dart';

class WaveformExtractor {
  static Future<Waveform> extract(String audioPath) async {
    final audioFile = File(audioPath);
    final waveFile = await WaveformCache.getWaveFile(audioPath);

    late Waveform waveform;

    await for (final progress in JustWaveform.extract(
      audioInFile: audioFile,
      waveOutFile: waveFile,
    )) {
      if (progress.waveform != null) {
        waveform = progress.waveform!;
      }
    }

    return waveform;
  }
}
