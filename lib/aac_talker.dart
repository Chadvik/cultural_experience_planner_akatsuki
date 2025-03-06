import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for typography

class AACTalkerScreen extends StatefulWidget {
  @override
  _AACTalkerScreenState createState() => _AACTalkerScreenState();
}

class _AACTalkerScreenState extends State<AACTalkerScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speechToText = stt.SpeechToText();

  String spokenText = "";
  bool isListening = false;
  String listeningPhrase = "";
  bool hasSpeechPermission = false;
  String currentLanguage = "en_US";

  @override
  void initState() {
    super.initState();
    _checkMicrophonePermission();
  }

  Future<void> _checkMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;
    if (!status.isGranted) status = await Permission.microphone.request();
    setState(() => hasSpeechPermission = status.isGranted);

    if (hasSpeechPermission) {
      bool available = await speechToText.initialize(
        onStatus: (status) => print("🎤 STT Status: $status"),
        onError: (error) => print("❌ STT Error: $error"),
      );
      if (!available) print("❌ Speech recognition not available!");
    }
  }

  Future<void> _speakPhrase(String phrase, String lang) async {
    await flutterTts.setLanguage(lang);
    await flutterTts.speak(phrase);
    setState(() {
      listeningPhrase = phrase;
      currentLanguage = lang;
    });
  }

  Future<void> _startListening() async {
    if (!hasSpeechPermission || !speechToText.isAvailable) return;

    setState(() {
      isListening = true;
      spokenText = "";
    });

    speechToText.listen(
      onResult: (result) {
        setState(() {
          spokenText = result.recognizedWords;
          isListening = false;
        });

        if (spokenText.isNotEmpty) {
          bool isCorrect = _compareText(spokenText, listeningPhrase);
          _showFeedbackDialog(spokenText, isCorrect);
        }
      },
      listenFor: Duration(seconds: 5),
      pauseFor: Duration(seconds: 2),
      localeId: currentLanguage,
    );
  }

  bool _compareText(String spoken, String expected) {
    return spoken.trim().toLowerCase() == expected.trim().toLowerCase();
  }

  void _showFeedbackDialog(String spoken, bool isCorrect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.error_outline,
              color: isCorrect ? Colors.green : Colors.redAccent,
            ),
            SizedBox(width: 10),
            Text(
              isCorrect ? "Well Done!" : "Try Again!",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          isCorrect
              ? "You nailed it! 🎉"
              : "Expected: \"$listeningPhrase\"\nYou said: \"$spoken\"",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Greetings Across India",
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent[700],
        elevation: 4,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("aac_phrasesss").snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            }

            var phrases = snapshot.data!.docs;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75, // Adjusted for better card proportions
                ),
                itemCount: phrases.length,
                itemBuilder: (context, index) {
                  var phraseData = phrases[index].data() as Map<String, dynamic>;

                  String phrase = phraseData['text'] ?? "No text";
                  String imageUrl = phraseData['image'] ?? "https://via.placeholder.com/100";
                  String lang = phraseData['lang'] ?? "en_US";
                  String state = phraseData['state'] ?? "Unknown State";

                  return GestureDetector(
                    onTap: () => _speakPhrase(phrase, lang),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blueAccent[100]!, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              imageUrl,
                              height: 80,
                              width: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),

                          // Phrase
                          Text(
                            phrase,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8),

                          // State
                          Text(
                            state,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.volume_up,
                                color: Colors.teal,
                                label: "Hear",
                                onPressed: () => _speakPhrase(phrase, lang),
                              ),
                              SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.mic,
                                color: Colors.orangeAccent,
                                label: "Say",
                                onPressed: _startListening,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}