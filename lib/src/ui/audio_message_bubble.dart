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
  final AudioMessageConfig config;

  const AudioMessage({
    super.key,
    required this.audioPath,
    this.isSender = true,
    this.config = const AudioMessageConfig(),
    this.profileImageUrl,
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
      if (_speed == 1.0) _speed = 1.5;
      else if (_speed == 1.5) _speed = 2.0;
      else _speed = 1.0;
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
      });
    });

    // ⏱ Listen duration (once)
    _player.durationStream.listen((dur) {
      if (!mounted || dur == null) return;
      setState(() => _totalDuration = dur);
    });

    setState(() {});
  }


  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.isSender ? Colors.green[50] : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Align(
        alignment:
        widget.isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: widget.isSender
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isSender) _buildAvatar(),

            CustomPaint(
              painter: BubblePainter(
                widget.isSender,
                widget.isSender ? Colors.green[50]! : Colors.grey[200]!,
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _player.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () =>
                      _player.isPlaying ? _player.pause() : _player.play(),
                    ),

                    if (widget.config.showPlaybackSpeed)
                      GestureDetector(
                        onTap: _toggleSpeed,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${_speed}x',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    SizedBox(
                      width: 120,
                      height: 40,
                      child: CustomPaint(
                        painter: WaveformPainter(
                          amplitudes: _amps,
                          progress: _progress,
                          active: widget.config.activeWaveColor,
                          inactive: widget.config.inactiveWaveColor,
                          barWidth: widget.config.barWidth,
                          spacing: widget.config.spacing,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (widget.isSender) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final isUrl = _isUrl(widget.audioPath);

    // 🟢 Online audio → show profile pic
    if (isUrl && widget.profileImageUrl != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: NetworkImage(widget.profileImageUrl!),
        backgroundColor: Colors.grey[300],
      );
    }

    // 🎤 Local audio → default WhatsApp mic
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.mic,
        size: 18,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildStatus() {
    if (!widget.config.showSeenStatus) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.config.time,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.done_all,
          size: 14,
          color: widget.config.isSeen ? Colors.blue : Colors.grey,
        ),
      ],
    );
  }


}
