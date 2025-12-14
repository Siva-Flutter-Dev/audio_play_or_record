import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_play_or_record/audio_play_or_record.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(debugShowCheckedModeBanner: false, home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeS()),
              );
            },
            icon: Icon(Icons.record_voice_over),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 120,
          child: AudioMessage(
            waveWidth: MediaQuery.of(context).size.width - 120,
            isSender: true,
            isProfile: false,
            audioPath:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            config: AudioMessageConfig(
              waveStyle: WaveStyle.whatsapp,
              showDuration: false,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeS extends StatefulWidget {
  const HomeS({super.key});

  @override
  State<HomeS> createState() => _HomeSState();
}

class _HomeSState extends State<HomeS> {
  bool _micGranted = false;
  final ctl = TextEditingController();
  String? audio;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.request();
    setState(() => _micGranted = status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.record_voice_over),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.width,
          child: RecordMicButton(
            onRecorded: (path) {
              setState(() {
                audio = path;
              });
            },
            onDelete: () {
              setState(() {
                audio = null;
              });
            },
            isSendEnable: ctl.text.isNotEmpty || audio != null,
            audioPath: audio,
            onMessageSend: () {},
            config: RecordButtonConfig(enableLock: true, enableHaptics: true),
            hasMicPermission: _micGranted,
          ),
        ),
      ),
    );
  }
}
