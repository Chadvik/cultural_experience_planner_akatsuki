import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;

  const MessageScreen({
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final JitsiMeet _jitsiMeetPlugin = JitsiMeet();
  bool _isMeetingActive = false;
  int? _userRating;

  void _sendMessage({required String messageText}) {
    if (messageText.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': currentUserId,
      });
      _messageController.clear();
    }
  }

  void _startVideoCall() async {
    try {
      setState(() => _isMeetingActive = true);
      var roomId = "guide_${widget.chatId}";
      var options = JitsiMeetConferenceOptions(
        room: roomId,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: FirebaseAuth.instance.currentUser!.displayName ?? 'User',
          email: FirebaseAuth.instance.currentUser!.email,
        ),
      );

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("Conference Joined: $url");
        },
        conferenceTerminated: (url, error) {
          debugPrint("Conference Terminated: $url, Error: $error");
          _endMeeting();
        },
        conferenceWillJoin: (url) {
          debugPrint("Conference Will Join: $url");
        },
      );

      await _jitsiMeetPlugin.join(options, listener);

      // Send meeting link in chat
      var meetingLink = "Join the meeting: https://meet.jit.si/$roomId";
      _sendMessage(messageText: meetingLink);

      // Automatically end after 5 minutes
      Future.delayed(const Duration(minutes: 5), () async {
        await _jitsiMeetPlugin.hangUp();
        _endMeeting();
      });
    } catch (error) {
      print("Error starting video call: $error");
      setState(() => _isMeetingActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to start video call")),
      );
    }
  }

  void _endMeeting() async {
    setState(() => _isMeetingActive = false);
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    if (chatDoc.exists && !chatDoc['isCompleted']) {
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        'isCompleted': true,
        'endTime': FieldValue.serverTimestamp(),
      });
      _showRatingDialog();
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rate Your Experience", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("How would you rate this guide?"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < (_userRating ?? 0) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _userRating = index + 1),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_userRating != null) {
                _submitRating();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a rating")),
                );
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userRating == null) return;

    final guideRef = FirebaseFirestore.instance.collection('guides').doc(widget.receiverId);
    await guideRef.update({
      'points': FieldValue.increment(_userRating!),
      'ratingCount': FieldValue.increment(1),
      'rating': FieldValue.increment(_userRating! / 5), // Adjust average rating
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'rating': _userRating,
      'ratedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rating submitted successfully!")),
    );
    setState(() => _userRating = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage('https://example.com/profile_pic.jpg'),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(
              widget.receiverName,
              style: GoogleFonts.poppins(
                color: Colors.teal[800],
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF5EEDC),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          if (!_isMeetingActive)
            Tooltip(
              message: "Start Video Call",
              child: IconButton(
                icon: Icon(Icons.videocam, color: Colors.teal[800]),
                onPressed: _startVideoCall,
              ),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF5EEDC),
      body: Column(
        children: [
          // Messages Display Section
          Expanded(
            child: SingleChildScrollView( // Prevent overflow in messages
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(widget.chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet.',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  var messages = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      var isMe = message['senderId'] == currentUserId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal[200] : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(10),
                              topRight: const Radius.circular(10),
                              bottomLeft: isMe
                                  ? const Radius.circular(10)
                                  : const Radius.circular(0),
                              bottomRight: isMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(10),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            message['text'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Input and Send Button Section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendMessage(messageText: _messageController.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10), // Extra padding to prevent overflow
        ],
      ),
    );
  }
}