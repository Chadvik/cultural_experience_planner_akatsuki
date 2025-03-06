import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final Gemini gemini = Gemini.instance;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  List<ChatMessage> messages = [];
  final ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  final ChatUser botUser = ChatUser(
    id: "1",
    firstName: "Chat Bot",
    profileImage: "https://cdn-icons-png.flaticon.com/128/8943/8943377.png",
  );

  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeechToText();
    _initTextToSpeech();
  }

  /// **🎤 Initialize Speech-to-Text**
  Future<void> _initSpeechToText() async {
    bool available = await _speechToText.initialize();
    setState(() {
      _isListening = available;
    });
  }

  /// **📢 Initialize Text-to-Speech**
  Future<void> _initTextToSpeech() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Slow speech for better understanding
  }

  /// **🎤 Start Listening (Speech to Text)**
  void _startListening() async {
    if (!_isListening) return;
    await _speechToText.listen(onResult: (result) {
      if (result.finalResult) {
        _handleMessage(ChatMessage(
          user: currentUser,
          text: result.recognizedWords,
          createdAt: DateTime.now(),
        ));
      }
    });
  }

  /// **📢 Speak Text (Text to Speech)**
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  /// **📩 Handle User Message & Generate AI Response**
  void _handleMessage(ChatMessage chatMessage) {
    setState(() {
      messages.insert(0, chatMessage);
    });

    try {
      String question = chatMessage.text;
      String botResponse = ""; // Collect the entire response

      gemini.promptStream(parts: [Part.text(question)]).listen(
            (response) {
          if (response?.output != null) {
            botResponse += response!.output! + " "; // Append response parts

            setState(() {
              // Remove the last bot response if it exists, and insert an updated one
              messages.removeWhere((msg) => msg.user == botUser);

              messages.insert(
                0,
                ChatMessage(
                  user: botUser,
                  text: botResponse,
                  createdAt: DateTime.now(),
                ),
              );
            });
          }
        },
        onDone: () {
          _speak(botResponse.trim()); // Speak the full response after completion
        },
        onError: (e) {
          print("Error: $e");
        },
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chatbot")),
      body: Column(
        children: [
          Expanded(
            child: DashChat(
              currentUser: currentUser,
              onSend: _handleMessage,
              messages: messages,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.orangeAccent,
                  child: Icon(Icons.mic, color: Colors.white),
                  onPressed: _startListening,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      _handleMessage(ChatMessage(
                        user: currentUser,
                        text: text,
                        createdAt: DateTime.now(),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
