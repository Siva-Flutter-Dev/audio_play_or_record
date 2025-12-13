import 'dart:ui';

enum WaveStyle { whatsapp, bars, dots, line }

class AudioMessageConfig {
  final WaveStyle waveStyle;
  final double barWidth;
  final bool showSeenStatus;
  final bool showPlaybackSpeed;
  final double spacing;
  final double animationSpeed;
  final bool enableSeek;
  final bool showDuration;
  final String time;
  final bool isSeen;

  final Color activeWaveColor;
  final Color inactiveWaveColor;
  final Color recordingWaveColor;

  const AudioMessageConfig({
    this.waveStyle = WaveStyle.whatsapp,
    this.barWidth = 3,
    this.spacing = 2,
    this.animationSpeed = 1.0,
    this.showSeenStatus = false,
    this.showPlaybackSpeed = false,
    this.enableSeek = true,
    this.showDuration = true,
    this.activeWaveColor = const Color(0xFF25D366),
    this.inactiveWaveColor = const Color(0xFFB0B0B0),
    this.recordingWaveColor = const Color(0xFFE53935),
    this.time = '',
    this.isSeen = false,
  });
}
