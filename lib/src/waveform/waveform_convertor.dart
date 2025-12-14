class WaveformConverter {
  static List<double> toAmplitudes(List<double> samples, int bars) {
    if (samples.isEmpty) return List.filled(bars, 0.3);

    final chunkSize = (samples.length / bars).floor();
    final result = <double>[];

    for (int i = 0; i < bars; i++) {
      final start = i * chunkSize;
      final end = start + chunkSize;

      double sum = 0;
      for (int j = start; j < end && j < samples.length; j++) {
        sum += samples[j].abs();
      }

      result.add(sum / chunkSize);
    }

    // 🔥 Normalize to 0–1
    final maxAmp = result.reduce((a, b) => a > b ? a : b);

    return result.map((v) {
      final normalized = maxAmp == 0 ? 0 : v / maxAmp;
      return normalized.clamp(0.15, 1.0).toDouble(); // 👈 WhatsApp look
    }).toList();
  }
}
