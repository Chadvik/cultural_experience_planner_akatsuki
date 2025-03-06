import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class HistoryPage extends StatefulWidget {
  final String historyText;
  HistoryPage({required this.historyText});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  @override
  void dispose() {
    flutterTts.stop(); // Stop TTS when page is closed
    super.dispose();
  }

  /// 📌 Start & Stop Text-to-Speech
  Future<void> _toggleSpeech() async {
    if (isSpeaking) {
      await flutterTts.stop();
      setState(() => isSpeaking = false);
    } else {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.0);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.speak(widget.historyText);
      setState(() => isSpeaking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Khajrana Temple History"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 📌 Temple Image
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset("assets/khajrana_temple.jpg"),
              ),
              SizedBox(height: 20),

              /// 📌 History Title
              Text(
                "History of Khajrana Temple",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              SizedBox(height: 10),

              /// 📌 History Text
              Text(
                widget.historyText,
                style: TextStyle(fontSize: 18, height: 1.5),
              ),
              SizedBox(height: 20),

              /// 📌 Play/Pause Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _toggleSpeech,
                  icon: Icon(isSpeaking ? Icons.pause_circle_filled : Icons.play_circle_filled),
                  label: Text(isSpeaking ? "Pause" : "Listen"),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
                    backgroundColor: Colors.deepPurple,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
