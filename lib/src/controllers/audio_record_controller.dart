import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderController {
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;

  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    _filePath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _filePath!,
    );
  }

  Future<String?> stop() async {
    await _recorder.stop();
    return _filePath;
  }

  Future<void> cancel() async {
    await _recorder.stop();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
