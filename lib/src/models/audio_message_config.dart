
import 'package:flutter/material.dart';

enum WaveStyle { whatsapp, bars, dots, line }

class AudioMessageConfig {
  final WaveStyle waveStyle;
  final double barWidth;
  final bool showPlaybackSpeed;
  final double spacing;
  final double animationSpeed;
  final bool enableSeek;
  final bool showDuration;
  final Color activeWaveColor;
  final Color inactiveWaveColor;
  final Color recordingWaveColor;

  const AudioMessageConfig({
    this.waveStyle = WaveStyle.whatsapp,
    this.barWidth = 3,
    this.spacing = 2,
    this.animationSpeed = 1.0,
    this.showPlaybackSpeed = false,
    this.enableSeek = true,
    this.showDuration = true,
    this.activeWaveColor = Colors.blue,
    this.inactiveWaveColor = Colors.black12,
    this.recordingWaveColor = Colors.red,
  });
}
