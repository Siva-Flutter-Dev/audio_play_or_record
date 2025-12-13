import 'package:flutter/cupertino.dart';

enum RecordState { idle, recording, locked }

enum WaveDirection { left, center, right }

enum OverlayMode { recording, playback }

class RecordButtonConfig {
  final bool enableLock;
  final bool enableHaptics;
  final bool enableTapRecord;
  final String? audioPath;
  final WaveDirection waveDirection;
  final MainAxisAlignment micAlignment;

  const RecordButtonConfig({
    this.enableLock = false,
    this.enableHaptics = false,
    this.enableTapRecord = true,
    this.audioPath,
    this.waveDirection = WaveDirection.left,
    this.micAlignment = MainAxisAlignment.spaceBetween,
  });
}
