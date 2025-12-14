import 'package:flutter/cupertino.dart';

/// The current state of the record button.
enum RecordState { idle, recording, locked }

/// The direction of the waveform animation.
enum WaveDirection { left, center, right }

/// Mode of the overlay (used in RecordMicButton UI).
enum OverlayMode { recording, playback }

/// Configuration options for the `RecordMicButton`.
///
/// Allows customization of recording behavior, haptics, waveform direction,
/// button alignment, and optional preloaded audio.
class RecordButtonConfig {
  /// Enables the lock-to-record functionality.
  final bool enableLock;

  /// Enables haptic feedback when interacting with the button.
  final bool enableHaptics;

  /// Enables tap-to-record functionality (as opposed to long-press only).
  final bool enableTapRecord;

  /// Optional audio path to prefill or play.
  final String? audioPath;

  /// Direction of the waveform animation.
  final WaveDirection waveDirection;

  /// Alignment of the microphone button within its parent.
  final MainAxisAlignment micAlignment;

  /// Creates a new configuration for the record button.
  ///
  /// [enableLock] – lock-to-record enabled if true.
  /// [enableHaptics] – haptic feedback enabled if true.
  /// [enableTapRecord] – allows tap-to-record if true.
  /// [audioPath] – optional preloaded audio file path.
  /// [waveDirection] – direction of waveform animation.
  /// [micAlignment] – alignment of the microphone button.

  const RecordButtonConfig({
    this.enableLock = false,
    this.enableHaptics = false,
    this.enableTapRecord = true,
    this.audioPath,
    this.waveDirection = WaveDirection.left,
    this.micAlignment = MainAxisAlignment.spaceBetween,
  });
}
