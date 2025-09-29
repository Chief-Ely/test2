// lib/stt.dart
//
// STT service wrapper using `speech_to_text` plugin.
// - Fixed imports so SpeechRecognitionResult and SpeechRecognitionError are available.
// - Handles permission, init, start/stop and exposes ValueNotifiers for UI binding.
//
// Make sure you have these dependencies in pubspec.yaml:
//   speech_to_text: ^7.3.0
//   permission_handler: ^10.4.0  (or latest)

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

// Core plugin (aliased because we use the SpeechToText class from it)
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Types are in separate files — import them so the Dart analyzer knows the classes.
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Small STT service: initialize, start/stop, and provide live transcript updates.
/// Use from UI: call init() once, then toggleListening() to start/stop.
class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Exposed for UI binding
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> transcript = ValueNotifier<String>('');

  bool _available = false;

  /// Request mic permission and initialize the plugin.
  Future<bool> init() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      transcript.value = 'Microphone permission denied.';
      _available = false;
      return false;
    }

    try {
      _available = await _speech.initialize(
        onError: (SpeechRecognitionError error) {
          // Use the imported class type here.
          transcript.value = 'Speech error: ${error.errorMsg}';
          isListening.value = false;
        },
        onStatus: (String status) {
          if (kDebugMode) {
            // print('STT status: $status');
          }
          // no additional mapping required here (we rely on start/stop)
        },
      );
    } catch (e) {
      _available = false;
      transcript.value = 'Failed to initialize speech: $e';
    }

    return _available;
  }

  /// Start listening (live partial results will appear in transcript).
  Future<void> startListening() async {
    if (!_available) {
      final ok = await init();
      if (!ok) return;
    }

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        // result.recognizedWords is the running transcript
        transcript.value = result.recognizedWords;
      },
      // You can add options like localeId or listenFor / partialResults here.
      // Example (optional):
      // listenFor: Duration(seconds: 30),
      // localeId: 'en_US',
    );

    isListening.value = true;
  }

  /// Stop listening.
  Future<void> stopListening() async {
    await _speech.stop();
    isListening.value = false;
  }

  /// Toggle listening on/off.
  Future<void> toggleListening() async {
    if (isListening.value || _speech.isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  bool get isAvailable => _available;

  /// Clean up resources
  void dispose() {
    isListening.dispose();
    transcript.dispose();
    _speech.cancel(); // cancel any in-progress recognition
  }
}
