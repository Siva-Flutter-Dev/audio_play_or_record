import 'package:flutter/cupertino.dart';

enum RecordState { idle, recording, locked }

enum WaveDirection { left, center, right }

class RecordButtonConfig {
  final bool enableLock;
  final bool enableHaptics;
  final bool enableTapRecord;
  final WaveDirection waveDirection;
  final Alignment micAlignment;

  const RecordButtonConfig({
    this.enableLock = false,
    this.enableHaptics = false,
    this.enableTapRecord = true,
    this.waveDirection = WaveDirection.left,
    this.micAlignment = Alignment.bottomCenter,
  });
}
