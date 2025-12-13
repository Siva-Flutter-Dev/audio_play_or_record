import 'package:just_audio/just_audio.dart';

class AudioPlayerController {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;

  Future<void> load(String path) async {
    await _player.setFilePath(path);
  }

  void play() => _player.play();
  void pause() => _player.pause();

  void seek(Duration d) => _player.seek(d);

  void dispose() => _player.dispose();
}
