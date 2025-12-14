/// audio_play_or_record
///
/// A Flutter package for recording and playing audio messages with interactive
/// waveform visualization, seek support, and chat-style UI inspired by WhatsApp.
///
/// ## Package Dependencies:
/// - `record` (6.1.2): Handles audio recording from the microphone.
/// - `just_audio` (0.10.5): Audio playback support for local or network files.
/// - `just_waveform` (0.0.7): Generates waveform data for visualizations.
/// - `path_provider` (2.1.2): Access device storage to save audio recordings.
/// - `flutter_animate` (4.5.0): Animations for waveforms and buttons.
///
/// ## Features
/// - Record audio using tap or long-press gestures.
/// - Playback audio with an interactive waveform.
/// - Seekable waveform for precise navigation.
/// - Animated waveform during recording.
/// - Fully customizable UI (colors, icons, layouts, and styles).
library;

/// Configuration for audio message waveform and UI options.
export 'src/models/audio_message_config.dart';

/// Configuration for the microphone recording button.
export 'src/models/record_button_config.dart';

/// Widget to display a chat-style audio message bubble with playback.
export 'src/ui/audio_message_bubble.dart';

/// Widget for recording audio with tap/long-press, waveform, and send button.
export 'src/ui/record_mic_button.dart';

/// Controller to manage audio recording operations.
export 'src/controllers/audio_record_controller.dart';
