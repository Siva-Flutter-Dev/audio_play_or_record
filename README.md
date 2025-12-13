🎧 audio_play_or_record

A Flutter package for recording audio, playing it back, and displaying
interactive waveforms with seek support (WhatsApp-style).

✨ Features

🎙 Audio recording (tap / long-press)

▶️ Audio playback with waveform

⏱ Tap & drag waveform to seek

🎚 Animated waveform while recording

🧩 Fully customizable UI (colors, icons, layout)

📦 Installation

Add this to your pubspec.yaml:

`dependencies:
audio_play_or_record: ^1.0.0`


Then run:

`flutter pub get`

🔐 Permissions
✅ Android

```
📍 android/app/src/main/AndroidManifest.xml

<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```
🍎 iOS
```
📍 ios/Runner/Info.plist

<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio.</string>

<key>NSAppTransportSecurity</key>
<dict>
<key>NSAllowsArbitraryLoads</key>
<true/>
</dict>
```

🎯 Runtime Permission (Android)

Request microphone permission in the host app:
```
import 'package:permission_handler/permission_handler.dart';

await Permission.microphone.request();
```

ℹ️ permission_handler is required only in the host app, not inside this package.


🧱 Basic Usage
🔊 Audio Message Player
```
AudioMessage(
audioPath: path,
config: AudioMessageConfig(
activeWaveColor: Colors.greenAccent,
inactiveWaveColor: Colors.black26,
),
)
```

🎤 Record Mic Button
```
RecordMicButton(
hasMicPermission: true,
onRecorded: (path) {
print("Recorded file: $path");
},
onMessageSend: () {},
)
```

🎨 Customization

You can customize:
```
Waveform colors

Bar width & spacing

Icons (mic, play, pause, delete)

Button size & padding

Recording behavior (tap / long-press / lock)
```
📱 Supported Platforms

✅ Android

✅ iOS

🛠 Dependencies Used
```
* dart:io – For handling audio files and file system operations.

* flutter/material – For UI widgets like buttons, icons, and layout.

* path_provider – To access device directories for saving audio files.

* permission_handler – Not included in the package; the host app must request microphone permission at runtime if needed.
```

📄 License
```
MIT License

Copyright (c) 2025 Bala Sivanantham <mbalasivanantham@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
...
