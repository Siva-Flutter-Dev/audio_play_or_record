import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/audio_player_controller.dart';
import '../models/audio_message_config.dart';
import '../painters/bubble_painter.dart';
import '../painters/waveform_painter.dart';
import '../waveform/waveform_convertor.dart';
import '../waveform/waveform_extractor.dart';

/// A widget that displays an audio message with playback and an interactive waveform.
///
/// Supports local and network audio files, sender/receiver styling, optional
/// profile images, and duration display. Includes full customization options
/// for colors, icons, and waveform appearance.
class AudioMessage extends StatefulWidget {
  /// The path or URL of the audio file to play.
  final String audioPath;

  /// URL of the profile image/avatar to display.
  ///
  /// If `null`, no profile image will be shown.
  final String? profileImageUrl;

  /// Whether this message was sent by the current user.
  ///
  /// Determines alignment and styling of the bubble.
  final bool isSender;

  /// Whether to show a profile image/avatar next to the message.
  final bool isProfile;

  /// Whether to show a profile image/avatar next to the message.
  final bool withBackground;

  /// Width of the waveform widget.
  final double waveWidth;

  /// Color of the operation icons (play, pause, delete).
  final Color iconColor;

  /// Background color of the audio message container.
  final Color backgroundColor;

  /// Configuration options for waveform style, colors, and playback behavior.
  final AudioMessageConfig config;

  /// Creates a new `AudioMessage` widget.
  ///
  /// [audioPath] – path or URL of the audio file (required).
  /// [waveWidth] – width of the waveform display (required).
  /// [isSender] – alignment and bubble styling; defaults to `true`.
  /// [isProfile] – whether to show profile image; defaults to `true`.
  /// [profileImageUrl] – optional avatar URL; defaults to `null`.
  /// [iconColor] – color for operation icons; defaults to `Colors.black`.
  /// [backgroundColor] – container background color; defaults to `Colors.white`.
  /// [config] – optional `AudioMessageConfig` for customization; defaults to `AudioMessageConfig()`.

  const AudioMessage({
    super.key,
    required this.audioPath,
    required this.waveWidth,
    this.isSender = true,
    this.isProfile = true,
    this.withBackground = true,
    this.config = const AudioMessageConfig(),
    this.profileImageUrl,
    this.iconColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  State<AudioMessage> createState() => _WhatsAppAudioMessageState();
}

/// State class for `AudioMessage` that handles audio playback and waveform visualization.
class _WhatsAppAudioMessageState extends State<AudioMessage> {
  /// Audio player controller for playback.
  final _player = AudioPlayerController();

  /// List of normalized amplitude values for waveform bars.
  List<double> _amps = [];

  /// Current playback progress (0.0 to 1.0).
  double progress = 0;

  /// Total duration of the audio file.
  Duration? _totalDuration;

  /// Current playback position.
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Formats a [Duration] into `mm:ss` string.
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Checks whether the given [path] is a network URL.
  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Generates a fake waveform for network audio files.
  ///
  /// [bars] – number of bars to generate.
  List<double> generateFakeWave(int bars) {
    final rnd = Random();
    return List.generate(
      bars,
      (_) => (rnd.nextDouble() * 0.6 + 0.3).clamp(0.3, 0.9),
    );
  }

  /// Initializes the audio player, waveform data, and listeners.
  Future<void> _init() async {
    final isUrl = _isUrl(widget.audioPath);

    await _player.load(widget.audioPath, isUrl: isUrl);

    // Waveform extraction for local files
    if (!isUrl) {
      final waveform = await WaveformExtractor.extract(widget.audioPath);
      final samples = waveform.data.map((s) => s.toDouble()).toList();
      _amps = WaveformConverter.toAmplitudes(samples, 45);
    } else {
      _amps = generateFakeWave(45);
    }

    // Listen to position updates
    _player.positionStream.listen((pos) {
      if (!mounted) return;

      setState(() {
        _currentPosition = pos;
        if (_totalDuration != null) {
          progress = pos.inMilliseconds / _totalDuration!.inMilliseconds;
        }

        // Stop and reset if reached the end
        if (_totalDuration != null &&
            pos >= _totalDuration! &&
            _player.isPlaying) {
          _player.pause();
          _player.seek(Duration.zero);
          _currentPosition = Duration.zero;
          progress = 0;
        }
      });
    });

    // Listen to duration (once)
    _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _totalDuration = dur);
    });

    setState(() {});
  }

  /// Seeks the audio to a position based on the tapped X coordinate.
  ///
  /// [tapX] – X position of the tap within the waveform widget.
  /// [width] – width of the waveform widget.
  void _seekToPosition(double tapX, double width) {
    if (_totalDuration == null) return;

    final percent = (tapX / width).clamp(0.0, 1.0);
    final targetMillis = (_totalDuration!.inMilliseconds * percent).toInt();
    final target = Duration(milliseconds: targetMillis);

    _player.seek(target);

    setState(() {
      _currentPosition = target;
      progress = percent;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Screen dimensions for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive paddings and sizes
    final bubblePaddingHorizontal = screenWidth * 0.03; // 3% horizontal padding
    final bubblePaddingVertical = screenHeight * 0.008; // ~1% vertical padding
    final avatarSize = screenWidth * 0.09; // 9% of screen width
    final waveformHeight = screenHeight * 0.05; // 5% of screen height

    return Row(
      mainAxisAlignment: widget.isSender
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Audio message bubble
              CustomPaint(
                painter: widget.withBackground
                    ? BubblePainter(widget.isSender, widget.backgroundColor)
                    : null,
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(
                        horizontal: bubblePaddingHorizontal,
                        vertical: bubblePaddingVertical,
                      ).copyWith(
                        right:
                            bubblePaddingHorizontal +
                            avatarSize, // space for avatar
                      ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row: Play button + waveform + optional avatar
                      Row(
                        children: [
                          // Play / Pause button
                          IconButton(
                            icon: Icon(
                              _player.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: screenWidth * 0.07,
                              color: widget.iconColor,
                            ),
                            onPressed: () => _player.isPlaying
                                ? _player.pause()
                                : _player.play(),
                          ),

                          // Waveform display
                          Expanded(
                            child: SizedBox(
                              height: waveformHeight,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final barWidth = 3.0;
                                  final spacing = 2.0;
                                  final barCount =
                                      (availableWidth / (barWidth + spacing))
                                          .floor();
                                  if (_amps.isNotEmpty) {
                                    // Generate scaled amplitudes for display
                                    final amplitudes = List.generate(barCount, (
                                      i,
                                    ) {
                                      final index =
                                          (i * _amps.length / barCount).floor();
                                      return _amps[index.clamp(
                                        0,
                                        _amps.length - 1,
                                      )];
                                    });

                                    return GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTapDown: (details) => _seekToPosition(
                                        details.localPosition.dx,
                                        availableWidth,
                                      ),
                                      onHorizontalDragUpdate: (details) =>
                                          _seekToPosition(
                                            details.localPosition.dx,
                                            availableWidth,
                                          ),
                                      child: CustomPaint(
                                        size: Size(availableWidth, 56),
                                        painter: WaveformPainter(
                                          amplitudes: amplitudes,
                                          progress:
                                              (_totalDuration != null &&
                                                  _totalDuration!
                                                          .inMilliseconds >
                                                      0)
                                              ? (_currentPosition
                                                        .inMilliseconds /
                                                    _totalDuration!
                                                        .inMilliseconds)
                                              : 0.0,
                                          active: widget.config.activeWaveColor,
                                          inactive:
                                              widget.config.inactiveWaveColor,
                                          barWidth: barWidth,
                                          spacing: spacing,
                                        ),
                                      ),
                                    );
                                  }

                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),

                          // Optional profile avatar
                          if (widget.isProfile) SizedBox(width: 5),
                          if (widget.isProfile)
                            SizedBox(
                              width: avatarSize,
                              height: avatarSize,
                              child: _buildAvatar(),
                            ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.002),

                      // Row: Current duration / total duration
                      Padding(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: widget.isProfile ? 26 : 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Current playback position
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                fontSize: MediaQuery.textScalerOf(
                                  context,
                                ).scale(11),
                                color: widget.iconColor,
                              ),
                            ),

                            // Total audio duration
                            if (_totalDuration != null)
                              Text(
                                _formatDuration(_totalDuration!),
                                style: TextStyle(
                                  fontSize: MediaQuery.textScalerOf(
                                    context,
                                  ).scale(11),
                                  color: widget.iconColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    final isUrl = _isUrl(widget.audioPath);

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Main avatar
        CircleAvatar(
          radius: 18,
          backgroundColor: widget.config.activeWaveColor,
          backgroundImage: (isUrl && widget.profileImageUrl != null)
              ? NetworkImage(widget.profileImageUrl!)
              : null,
          child: (!isUrl || widget.profileImageUrl == null)
              ? Icon(Icons.person, size: 18, color: widget.backgroundColor)
              : null,
        ),

        // Small mic overlay
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 7,
            backgroundColor:
                widget.config.activeWaveColor, // WhatsApp mic bubble color
            child: Icon(Icons.mic, size: 10, color: widget.backgroundColor),
          ),
        ),
      ],
    );
  }
}
