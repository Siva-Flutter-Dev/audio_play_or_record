import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/audio_player_controller.dart';
import '../models/audio_message_config.dart';
import '../painters/bubble_painter.dart';
import '../painters/waveform_painter.dart';
import '../waveform/waveform_convertor.dart';
import '../waveform/waveform_extractor.dart';

class AudioMessage extends StatefulWidget {
  final String audioPath;
  final String? profileImageUrl;
  final bool isSender;
  final double waveWidth;
  final Color iconColor;
  final Color backgroundColor;
  final AudioMessageConfig config;

  const AudioMessage({
    super.key,
    required this.audioPath,
    required this.waveWidth,
    this.isSender = true,
    this.config = const AudioMessageConfig(),
    this.profileImageUrl,
    this.iconColor=Colors.black,
    this.backgroundColor=Colors.white,
  });

  @override
  State<AudioMessage> createState() => _WhatsAppAudioMessageState();
}

class _WhatsAppAudioMessageState extends State<AudioMessage> {
  final _player = AudioPlayerController();
  List<double> _amps = [];
  double _progress = 0;
  Duration? _totalDuration;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }


  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  double _speed = 1.0;

  void _toggleSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      }
      else {
        _speed = 1.0;
      }
    });
    _player.speed(_speed);
  }


  List<double> generateFakeWave(int bars) {
    final rnd = Random();
    return List.generate(
      bars,
          (_) => (rnd.nextDouble() * 0.6 + 0.3).clamp(0.3, 0.9),
    );
  }


  Future<void> _init() async {
    final isUrl = _isUrl(widget.audioPath);

    await _player.load(widget.audioPath, isUrl: isUrl);

    // Waveform
    if (!isUrl) {
      final waveform = await WaveformExtractor.extract(widget.audioPath);

      // Convert int samples to double (0.0 to 1.0)
      final samples = waveform.data.map((s) => s.toDouble()).toList();

      _amps = WaveformConverter.toAmplitudes(samples, 45);
    } else {
      _amps = generateFakeWave(45);
    }

    // 🎧 Listen position
    _player.positionStream.listen((pos) {
      if (!mounted) return;

      setState(() {
        _currentPosition = pos;
        if (_totalDuration != null) {
          _progress = pos.inMilliseconds / _totalDuration!.inMilliseconds;
        }

        if (_totalDuration != null &&
            pos >= _totalDuration! &&
            _player.isPlaying) {
          _player.pause();
          _player.seek(Duration.zero);
          _currentPosition = Duration.zero;
          _progress = 0;
        }
      });
    });

    // ⏱ Listen duration (once)
    _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _totalDuration = dur);
    });

    setState(() {});
  }

  void _seekToPosition(double tapX, double width) {
    if (_totalDuration == null) return;

    final percent = (tapX / width).clamp(0.0, 1.0);
    final targetMillis =
    (_totalDuration!.inMilliseconds * percent).toInt();

    final target = Duration(milliseconds: targetMillis);

    _player.seek(target);

    setState(() {
      _currentPosition = target;
      _progress = percent;
    });
  }



  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScale = MediaQuery.of(context).textScaleFactor;

    // Responsive sizes
    final bubblePaddingHorizontal = screenWidth * 0.03; // 3% of width
    final bubblePaddingVertical = screenHeight * 0.008; // ~1% of height
    final avatarSize = screenWidth * 0.09; // 9% of width
    final avatarOffset = avatarSize * 0.2; // offset for overlap
    final waveformHeight = screenHeight * 0.05; // 5% of height

    return Row(
      mainAxisAlignment: widget.isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Bubble
              CustomPaint(
                painter: BubblePainter(
                  widget.isSender,
                  widget.backgroundColor,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: bubblePaddingHorizontal,
                    vertical: bubblePaddingVertical,
                  ).copyWith(
                    right: bubblePaddingHorizontal + avatarSize, // space for avatar
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Play button + waveform
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _player.isPlaying ? Icons.pause : Icons.play_arrow,
                              size: screenWidth * 0.07, // responsive icon
                              color: widget.iconColor,
                            ),
                            onPressed: () =>
                            _player.isPlaying ? _player.pause() : _player.play(),
                          ),
                          SizedBox(width: screenWidth * 0.08),
                          Expanded(
                            child: SizedBox(
                              height: waveformHeight,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) {
                                      _seekToPosition(
                                        details.localPosition.dx,
                                        constraints.maxWidth,
                                      );
                                    },
                                    onHorizontalDragUpdate: (details) {
                                      _seekToPosition(
                                        details.localPosition.dx,
                                        constraints.maxWidth,
                                      );
                                    },
                                    child: CustomPaint(
                                      size: Size(widget.waveWidth, 55),
                                      painter: WaveformPainter(
                                        amplitudes: _amps,
                                        progress: _progress,
                                        active: widget.config.activeWaveColor,
                                        inactive: widget.config.inactiveWaveColor,
                                        barWidth: widget.config.barWidth,
                                        spacing: widget.config.spacing,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        ],
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      // Duration row
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: TextStyle(
                                fontSize: 10 * textScale,
                                color: widget.iconColor,
                              ),
                            ),
                            if (_totalDuration != null)
                              Text(
                                _formatDuration(_totalDuration!),
                                style: TextStyle(
                                  fontSize: 10 * textScale,
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

              // Avatar inside bubble
              if(widget.profileImageUrl!=null)
              Positioned(
                bottom: -avatarOffset,
                right: -avatarOffset,
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: _buildAvatar(),
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
              ? Icon(
            Icons.person,
            size: 18,
            color: widget.iconColor,
          )
              : null,
        ),

        // Small mic overlay
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 7,
            backgroundColor: widget.config.activeWaveColor, // WhatsApp mic bubble color
            child: Icon(
              Icons.mic,
              size: 10,
              color: widget.iconColor,
            ),
          ),
        ),
      ],
    );
  }

}
