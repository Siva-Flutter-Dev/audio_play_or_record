import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// A controller for recording audio using the `record` package.
///
/// Handles starting, stopping, canceling, and disposing audio recordings.
/// Saves recordings to the device's temporary directory in `.m4a` format.
class AudioRecorderController {
  /// The underlying `AudioRecorder` instance.
  final AudioRecorder _recorder = AudioRecorder();

  /// Path of the currently recorded audio file.
  String? _filePath;

  /// Starts recording audio and saves it to a temporary file.
  ///
  /// The file is saved in the device's temporary directory with a timestamped filename.
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

  /// Stops the current recording and returns the file path of the saved audio.
  ///
  /// Returns `null` if no recording was started.
  Future<String?> stop() async {
    await _recorder.stop();
    return _filePath;
  }

  /// Cancels the current recording without returning the file path.
  ///
  /// The recording file may still exist in temporary storage but is considered discarded.
  Future<void> cancel() async {
    await _recorder.stop();
  }

  /// Disposes the recorder and releases any resources.
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
