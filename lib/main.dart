// lib/main.dart
//
// Minimal app UI: single screen with a textfield showing transcript
// and a mic FloatingActionButton to start/stop listening.
//
// This uses the SttService from stt.dart.

import 'package:flutter/material.dart';
import 'stt.dart'; // <- the service file above

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple STT Demo (Android)',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SttService _stt = SttService();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // initialize STT service (asks for permission if needed)
    _stt.init();

    // listen to transcript updates and reflect them in the TextField
    _stt.transcript.addListener(() {
      _controller.text = _stt.transcript.value;
      // keep the cursor at the end for readability (even though readOnly)
      _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
      // if you want to force rebuild for isListening change, call setState in that notifier:
      setState(() {});
    });

    // we also use isListening notifier for icon state
    _stt.isListening.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _stt.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool listening = _stt.isListening.value;
    final String hint = !_stt.isAvailable
        ? 'STT not available or permission denied'
        : listening
            ? 'Listening... speak now'
            : 'Tap the mic to start listening';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech → Text (single UI)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hint,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),

            // Read-only text field for the transcript output
            TextField(
              controller: _controller,
              readOnly: true, // read-only output
              maxLines: null, // expand vertically as text grows
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Transcribed text will appear here',
              ),
            ),

            const SizedBox(height: 12),

            // Simple helper row (clears text, show status)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // clear transcript
                    _stt.transcript.value = '';
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 12),
                Text('Listening: ${listening ? "Yes" : "No"}'),
              ],
            ),
          ],
        ),
      ),

      // Mic FAB (start/stop)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _stt.toggleListening();
        },
        child: Icon(
          // show mic vs mic_off based on listening state
          _stt.isListening.value ? Icons.mic : Icons.mic_none,
        ),
      ),
    );
  }
}
