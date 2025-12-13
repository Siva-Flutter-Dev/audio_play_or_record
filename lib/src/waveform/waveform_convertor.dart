import 'dart:math';
import 'package:just_waveform/just_waveform.dart';

class WaveformConverter {
  static List<double> toAmplitudes(Waveform waveform, int bars) {
    final total = waveform.length;
    if (total == 0) return [];

    final step = max(1, (total / bars).floor());
    final result = <double>[];

    for (int i = 0; i < total; i += step) {
      final min = waveform.getPixelMin(i).toDouble();
      final maxV = waveform.getPixelMax(i).toDouble();
      result.add(max(min, maxV));
    }

    final maxAmp = result.reduce(max);
    return result.map((e) => e / maxAmp).toList();
  }
}
