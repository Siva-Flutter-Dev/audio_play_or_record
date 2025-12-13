import 'package:just_audio/just_audio.dart';

class AudioPlayerController {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  bool get isPlaying => _player.playing;


  Future<void> load(String path, {bool isUrl = false}) async {
    if (isUrl) {
      await _player.setUrl(path);
    } else {
      await _player.setFilePath(path);
    }
  }


  void play() => _player.play();
  void pause() => _player.pause();
  void volume() => _player.setVolume(1.0);

  void speed(double speed) => _player.setSpeed(speed);

  void seek(Duration d) => _player.seek(d);

  void dispose() => _player.dispose();
}
