import 'package:just_audio/just_audio.dart';

/// A controller for playing audio using the `just_audio` package.
///
/// Provides methods for loading, playing, pausing, seeking, adjusting speed,
/// and listening to audio position and duration streams.
class AudioPlayerController {
  /// The underlying `AudioPlayer` instance from just_audio.
  final AudioPlayer _player = AudioPlayer();

  /// Stream that emits the current playback position.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream that emits the total duration of the current audio.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Returns true if the audio is currently playing.
  bool get isPlaying => _player.playing;

  /// Loads an audio file from a local path or a URL.
  ///
  /// [path] – The file path or URL of the audio.
  /// [isUrl] – Set to `true` if [path] is a URL; defaults to `false`.
  Future<void> load(String path, {bool isUrl = false}) async {
    if (isUrl) {
      await _player.setUrl(path);
    } else {
      await _player.setFilePath(path);
    }
  }

  /// Starts or resumes audio playback.
  void play() => _player.play();

  /// Pauses audio playback.
  void pause() => _player.pause();

  /// Sets the audio volume to maximum (1.0).
  void volume() => _player.setVolume(1.0);

  /// Sets the playback speed.
  ///
  /// [speed] – Playback speed multiplier (e.g., 1.0 = normal, 2.0 = double speed).
  void speed(double speed) => _player.setSpeed(speed);

  /// Seeks to the specified position in the audio.
  ///
  /// [d] – The duration to seek to.
  void seek(Duration d) => _player.seek(d);

  /// Releases resources used by the audio player.
  void dispose() => _player.dispose();
}
