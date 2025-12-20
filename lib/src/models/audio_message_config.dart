import 'package:flutter/material.dart';

/// Configuration options for the `AudioMessage` widget.
///
/// Allows customization of waveform style, colors, spacing, animation, and playback behavior.
class AudioMessageConfig {
  /// The visual style of the waveform.
  final WaveStyle waveStyle;

  /// Width of each waveform bar (used for `bars` or `whatsapp` styles).
  final double barWidth;

  /// Width of each waveform bar (used for `bars` or `whatsapp` styles).
  final double barHeight;

  /// Space between waveform bars.
  final double spacing;

  /// Speed of waveform animation (higher = faster).
  final double animationSpeed;

  /// Whether to show playback speed control in the UI.
  final bool showPlaybackSpeed;

  /// Whether the waveform can be tapped or dragged to seek.
  final bool enableSeek;

  /// Whether to display the audio duration.
  final bool showDuration;

  /// Color of the active waveform (played portion).
  final Color activeWaveColor;

  /// Color of the inactive waveform (unplayed portion).
  final Color inactiveWaveColor;

  /// Color of the waveform while recording.
  final Color recordingWaveColor;

  /// Creates a new configuration for `AudioMessage`.
  ///
  /// All parameters are optional and have sensible defaults.
  const AudioMessageConfig({
    this.waveStyle = WaveStyle.whatsapp,
    this.barWidth = 3,
    this.barHeight = 3,
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

/// Styles available for rendering the audio waveform.
enum WaveStyle { whatsapp, bars, dots, line }
