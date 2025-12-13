import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WaveformCache {
  static Future<File> getWaveFile(String audioPath) async {
    final dir = await getTemporaryDirectory();
    final name = audioPath.split('/').last;
    return File('${dir.path}/$name.waveform');
  }

  static Future<bool> exists(String audioPath) async {
    final file = await getWaveFile(audioPath);
    return file.exists();
  }
}
