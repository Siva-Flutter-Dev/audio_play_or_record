import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/audio_player_controller.dart';
import '../models/audio_message_config.dart';
import '../painters/waveform_painter.dart';
import '../waveform/waveform_convertor.dart';
import '../waveform/waveform_extractor.dart';

class AudioMessage extends StatefulWidget {
  final String audioPath;
  final bool isSender;
  final AudioMessageConfig config;

  const AudioMessage({
    super.key,
    required this.audioPath,
    this.isSender = true,
    this.config = const AudioMessageConfig(),
  });

  @override
  State<AudioMessage> createState() => _WhatsAppAudioMessageState();
}

class _WhatsAppAudioMessageState extends State<AudioMessage> {
  final _player = AudioPlayerController();
  List<double> _amps = [];
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }


  Future<void> _init() async {
    final isUrl = _isUrl(widget.audioPath);

    // ✅ Load audio correctly
    await _player.load(widget.audioPath, isUrl: isUrl);

    // ✅ Only extract waveform for LOCAL files
    if (!isUrl) {
      final waveform = await WaveformExtractor.extract(widget.audioPath);
      _amps = WaveformConverter.toAmplitudes(waveform, 45);
    } else {
      _amps = List.filled(45, 0.3); // fallback bars
    }

    _player.positionStream.listen((pos) async {
      final dur = await _player.durationStream.first;
      if (!mounted || dur == null) return;
      setState(() => _progress = pos.inMilliseconds / dur.inMilliseconds);
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
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _player.isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.config.activeWaveColor,
            ),
            onPressed: () =>
            _player.isPlaying ? _player.pause() : _player.play(),
          ),
          Expanded(
            child: GestureDetector(
              onTapDown: (d) {
                if (!widget.config.enableSeek) return;
                final box = context.findRenderObject() as RenderBox;
                final dx = d.localPosition.dx;
                final percent = dx / box.size.width;
                final duration = _player.durationStream.first;
                duration.then((dur) {
                  if (dur != null) {
                    _player.seek(
                      Duration(milliseconds: (dur.inMilliseconds * percent).toInt()),
                    );
                  }
                });
              },
              child: CustomPaint(
                painter: WaveformPainter(
                  amplitudes: _amps,
                  progress: _progress,
                  active: widget.config.activeWaveColor,
                  inactive: widget.config.inactiveWaveColor,
                  barWidth: widget.config.barWidth,
                  spacing: widget.config.spacing,
                ),
                size: const Size(double.infinity, 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
