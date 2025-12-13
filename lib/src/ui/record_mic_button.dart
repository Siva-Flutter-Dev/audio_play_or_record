import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../controllers/audio_record_controller.dart';
import '../controllers/audio_player_controller.dart';
import '../models/record_button_config.dart';
import '../painters/waveform_painter.dart';
import 'package:flutter/services.dart';

class RecordMicButton extends StatefulWidget {
  final bool hasMicPermission;
  final bool isSendEnable;
  final double? overlayWidth;
  final double height;
  final RecordButtonConfig config;
  final Function(String path) onRecorded;
  final VoidCallback onMessageSend;
  final VoidCallback onDelete;
  final TextEditingController? textController;
  final InputDecoration? textFieldDecoration;
  final Widget? micIcon;
  String? audioPath;
  final Widget? stopIcon;
  final Widget? sendIcon;
  final double? buttonRadius;
  final Color primaryColor;
  final Color stopButtonColor;
  final Color iconColor;
  final Color iconWhileRecColor;
  final Color runningWave;
  final Color backgroundWave;
  final Color backgroundAudio;
  final EdgeInsets? buttonPadding;

  RecordMicButton({
    super.key,
    required this.onRecorded,
    required this.hasMicPermission,
    required this.onMessageSend,
    required this.onDelete,
    this.isSendEnable = false,
    this.height = 62,
    this.config = const RecordButtonConfig(),
    this.overlayWidth,
    this.textController,
    this.textFieldDecoration,
    this.micIcon,
    this.stopIcon,
    this.sendIcon,
    this.buttonRadius,
    this.primaryColor=Colors.blue,
    this.stopButtonColor=Colors.red,
    this.iconColor=Colors.white,
    this.iconWhileRecColor=Colors.black,
    this.runningWave=Colors.blue,
    this.backgroundWave=Colors.black12,
    this.backgroundAudio=Colors.white,
    this.buttonPadding,
    this.audioPath,
  });

  @override
  State<RecordMicButton> createState() => _RecordMicButtonState();
}

class _RecordMicButtonState extends State<RecordMicButton>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorderController();
  late final TextEditingController _controller;
  RecordState _state = RecordState.idle;
  Offset _start = Offset.zero;
  Duration _duration = Duration.zero;
  Timer? _timer;

  // Audio playback
  AudioPlayerController? _audioController;
  Duration _position = Duration.zero;
  Duration? _total;
  List<double> _waveformAmplitudes = [];
  final _rand = Random();
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _controller = widget.textController ?? TextEditingController();
    _controller.addListener(() => setState(() {}));

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // If audioPath is passed initially, init audio player
    if (widget.audioPath != null) _initPlayer(widget.audioPath!);
  }

  // @override
  // void didUpdateWidget(covariant RecordMicButton oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // If audioPath changes, init audio player again
  //   if (widget.audioPath != null && widget.audioPath != oldWidget.audioPath) {
  //     _initPlayer(widget.audioPath!);
  //   }
  // }

  Future<void> _initPlayer(String path) async {
    _audioController?.dispose();
    _audioController = AudioPlayerController();
    await _audioController?.load(path);

    // Dummy waveform, replace with real extraction if needed
    _waveformAmplitudes = List.generate(50, (_) => _rand.nextDouble());

    _audioController?.durationStream.listen((d) {
      if (mounted) setState(() => _total = d ?? Duration.zero);
    });
    _audioController?.positionStream.listen((p) {
      if (mounted) {
        setState((){
        _position = p;
        if (_total != null &&
            p >= _total! &&
            _audioController!.isPlaying) {
          _audioController?.pause();
          _audioController?.seek(Duration.zero);
          _position = Duration.zero;
        }
      });
      }
    });
  }

  void _haptic() {
    if (widget.config.enableHaptics) HapticFeedback.mediumImpact();
  }

  Future<void> _startRecord(LongPressStartDetails d) async {
    if (!widget.hasMicPermission || _state != RecordState.idle) return;
    _start = d.globalPosition;
    _duration = Duration.zero;

    await _recorder.start();
    _haptic();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration += const Duration(seconds: 1));
    });

    setState(() => _state = RecordState.recording);
  }

  Future<void> _tapStart() async {
    if (!widget.config.enableTapRecord || _state != RecordState.idle) return;
    await _startRecord(LongPressStartDetails(globalPosition: Offset.zero));
  }

  void _update(LongPressMoveUpdateDetails d) {
    final dx = _start.dx - d.globalPosition.dx;
    final dy = _start.dy - d.globalPosition.dy;
    if (dx > 80 && _state == RecordState.recording) _cancel();
    if (widget.config.enableLock && dy > 60 && _state == RecordState.recording) {
      _haptic();
      setState(() => _state = RecordState.locked);
    }
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path != null && mounted) {
      setState(() => _state = RecordState.idle);
      widget.onRecorded(path);
      _initPlayer(path); // init audio playback immediately
    } else {
      setState(() => _state = RecordState.idle);
    }
  }

  Future<void> _cancel() async {
    _haptic();
    _timer?.cancel();
    _timer = null;

    await _recorder.cancel();
    setState((){
      widget.onDelete.call();
      _audioController=null;
      _state = RecordState.idle;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _audioController?.dispose();
    if (widget.textController == null) _controller.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // Widget _wave() {
  //   if (_state == RecordState.recording) {
  //     // Animated random waveform
  //     return LayoutBuilder(
  //       builder: (_, c) {
  //         final bars = (c.maxWidth / 6).floor();
  //         return AnimatedBuilder(
  //           animation: _waveController,
  //           builder: (_, __) {
  //             return Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: List.generate(bars, (i) {
  //                 final h = 6 + _rand.nextInt(18);
  //                 return Padding(
  //                   padding: const EdgeInsets.symmetric(horizontal: 1),
  //                   child: Container(
  //                     width: 3,
  //                     height: h.toDouble(),
  //                     decoration: BoxDecoration(
  //                       color: Colors.greenAccent,
  //                       borderRadius: BorderRadius.circular(2),
  //                     ),
  //                   ),
  //                 );
  //               }),
  //             );
  //           },
  //         );
  //       },
  //     );
  //   } else if (_audioController != null) {
  //     // Playback waveform
  //     return CustomPaint(
  //       painter: WaveformPainter(
  //         amplitudes: _waveformAmplitudes,
  //         progress: (_total != null && _total!.inMilliseconds > 0)
  //             ? (_position.inMilliseconds / _total!.inMilliseconds)
  //             : 0,
  //         active: Colors.greenAccent,
  //         inactive: Colors.redAccent,
  //         barWidth: 3,
  //         spacing: 2,
  //       ),
  //       size: const Size(double.infinity, 56),
  //     );
  //   } else {
  //     return const SizedBox.shrink();
  //   }
  // }

  Widget _wave() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final barWidth = 3.0;
        final spacing = 2.0;
        final barCount = (availableWidth / (barWidth + spacing)).floor();

        List<double> amplitudes;
        if (_state == RecordState.recording) {
          // Animated random waveform for recording
          amplitudes = List.generate(barCount, (_) => _rand.nextDouble());
        } else if (_audioController != null) {
          // Playback waveform: use pre-extracted amplitudes
          if (_waveformAmplitudes.isEmpty) {
            amplitudes = List.generate(barCount, (_) => _rand.nextDouble());
          } else {
            // Resize to fit the available width
            amplitudes = List.generate(barCount, (i) {
              final index = (i * _waveformAmplitudes.length / barCount).floor();
              return _waveformAmplitudes[index.clamp(0, _waveformAmplitudes.length - 1)];
            });
          }
        } else {
          return const SizedBox.shrink();
        }

        if (_state == RecordState.recording) {
          return AnimatedBuilder(
            animation: _waveController,
            builder: (_, __) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: amplitudes.map((amp) {
                  final height = 6 + (amp * 18); // min 6, max 24
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                    child: Container(
                      width: barWidth,
                      height: height,
                      decoration: BoxDecoration(
                        color: widget.runningWave,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        } else {
          // Playback waveform
          return CustomPaint(
            painter: WaveformPainter(
              amplitudes: amplitudes,
              progress: (_total != null && _total!.inMilliseconds > 0)
                  ? (_position.inMilliseconds / _total!.inMilliseconds)
                  : 0.0,
              active: widget.runningWave,
              inactive: widget.backgroundWave,
              barWidth: barWidth,
              spacing: spacing,
            ),
            size: Size(availableWidth, 56),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSend = _controller.text.isNotEmpty || widget.isSendEnable;
    final isPlaying = _audioController?.isPlaying ?? false;

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: widget.config.micAlignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: (_state != RecordState.idle || _audioController != null)
                ? Container(
              width: widget.overlayWidth ?? width * 0.7,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: widget.backgroundAudio,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  // Delete button
                  IconButton(
                    icon: Icon(CupertinoIcons.delete, color: widget.stopButtonColor),
                    onPressed: _cancel,
                  ),
                  // Play/Pause button
                  if (_audioController != null)
                    IconButton(
                      icon: Icon(
                        _audioController!.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.iconWhileRecColor,
                      ),
                      onPressed: () {
                        if (_audioController != null) {
                          _audioController!.isPlaying
                              ? _audioController!.pause()
                              : _audioController!.play();
                        }
                      },
                    ),
                  Expanded(child: _wave()),
                  Text(
                    _state == RecordState.recording
                        ? _format(_duration)
                        : "${_format(_position)} / ${_format(_total ?? Duration.zero)}",
                    style: TextStyle(color: widget.iconWhileRecColor, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _state == RecordState.recording ? Icons.mic : Icons.volume_up,
                    color: widget.iconWhileRecColor,
                    size: 18,
                  ),
                ],
              ),
            )
                : TextField(
              controller: _controller,
              decoration: widget.textFieldDecoration ??
                  InputDecoration(
                    hintText: 'Type a message',
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: showSend
                ? widget.onMessageSend
                : (_state == RecordState.recording ? _stop : _tapStart),
            onLongPressStart: _startRecord,
            onLongPressMoveUpdate: _update,
            onLongPressEnd: (_) {
              if (_state == RecordState.recording) _stop();
            },
            child: Container(
              width: widget.height,
              height: widget.height,
              padding: widget.buttonPadding ?? EdgeInsets.zero,
              decoration: BoxDecoration(
                color: showSend
                    ? (widget.primaryColor)
                    : (_state == RecordState.idle
                    ? (widget.primaryColor)
                    : (widget.stopButtonColor)),
                borderRadius: BorderRadius.circular(widget.buttonRadius??50)
              ),
              child: Center(
                child: showSend
                    ? (widget.sendIcon ?? Icon(Icons.send, color: widget.iconColor))
                    : (_state == RecordState.idle
                    ? (widget.micIcon ?? Icon(Icons.mic, color: widget.iconColor))
                    : (widget.stopIcon ?? Icon(Icons.stop, color: widget.iconColor))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
