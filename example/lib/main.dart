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
      backgroundColor: Colors.grey,
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
            iconColor: Colors.white,
            backgroundColor: Colors.blueAccent,
            audioPath:
                'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
            config: AudioMessageConfig(
              waveStyle: WaveStyle.whatsapp,
              activeWaveColor: Colors.white,
              animationSpeed: 5,
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
      backgroundColor: Colors.white,
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
            height: 52,
            leadingIcon: Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Icon(Icons.add, color: Colors.blue)),
            ),
            onRecorded: (path) {
              setState(() {
                audio = path;
              });
            },
            onLeading: () {
              //print("object");
            },
            onDelete: () {
              setState(() {
                audio = null;
                ctl.clear();
              });
            },
            // audioDeleteIcon: Icon(Icons.verified),
            textField: TextField(
              controller: ctl,
              maxLines: 5,
              minLines: 1,
              onChanged: (v) {
                setState(() {});
              },
              decoration: InputDecoration(
                // isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide(color: Colors.black12),
                ),
              ),
            ),
            buttonRadius: 14,
            textController: ctl,
            isSendEnable: ctl.text.isNotEmpty || audio != null,
            audioPath: audio,
            onMessageSend: () {
              setState(() {
                audio = null;
              });
            },
            config: RecordButtonConfig(
              enableLock: true,
              enableHaptics: true,
              micAlignment: MainAxisAlignment.end,
            ),
            hasMicPermission: _micGranted,
          ),
        ),
      ),
    );
  }
}
