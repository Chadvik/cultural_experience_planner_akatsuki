import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class HawaMahalPage extends StatefulWidget {
  const HawaMahalPage({Key? key}) : super(key: key);

  @override
  State<HawaMahalPage> createState() => _HawaMahalPageState();
}

class _HawaMahalPageState extends State<HawaMahalPage> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  ConfettiController? _confettiController;
  bool isVideoInitialized = false;
  Map<String, dynamic>? itemData;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _fetchItemDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    _confettiController?.dispose();
    super.dispose();
  }

  void _fetchItemDetails() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('hawa_mahal')
              .where('title', isEqualTo: 'Hawa Mahal')
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          itemData = snapshot.docs.first.data() as Map<String, dynamic>;
        });
        if (itemData?['videoURL']?.isNotEmpty ?? false) {
          _initializeVideo(itemData!['videoURL']);
        }
        if (itemData?['audioURL']?.isNotEmpty ?? false) {
          _audioPlayer = AudioPlayer()..play(UrlSource(itemData!['audioURL']));
        }
        _incrementViews(snapshot.docs.first.id);
      } else {
        debugPrint('No document found for Hawa Mahal in hawa_mahal collection');
      }
    } catch (e) {
      debugPrint('Error fetching Hawa Mahal details: $e');
    }
  }

  void _initializeVideo(String videoURL) {
    _videoController = VideoPlayerController.network(videoURL)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            isVideoInitialized = true;
          });
          _videoController?.play();
        }
      });
  }

  void _incrementViews(String docId) async {
    if (itemData == null) return;
    DocumentReference ref = FirebaseFirestore.instance
        .collection('hawa_mahal')
        .doc(docId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        int newViews = (snapshot['views'] ?? 0) + 1;
        transaction.update(ref, {'views': newViews});
      }
    });
    setState(() {
      itemData!['views'] = (itemData!['views'] ?? 0) + 1;
    });
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (itemData == null) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
    }

    String title = itemData!['title'] ?? "Hawa Mahal";
    String description =
        itemData!['description'] ?? "Feel the whispers of history!";
    String imageURL = itemData!['imageURL'] ?? "";
    int views = itemData!['views'] ?? 0;
    String actionURL =
        itemData!['actionURL'] ?? "https://example.com/visit-hawa-mahal";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white, // Ensure title is visible
            fontSize: 20,
          ),
        ).animate().slideX(duration: 500.ms),
        backgroundColor: Colors.pink[700], // Distinct background color
        elevation: 4, // Add shadow for depth
        actions: [
          // "Feel the Breeze" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ElevatedButton(
              onPressed: () => _confettiController?.play(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Contrast with AppBar
                foregroundColor: Colors.pink[700], // Text/icon color
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text("Feel the Breeze"),
            ),
          ),
          // "Visit Now" button
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: ElevatedButton(
              onPressed: () => _launchURL(actionURL),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.pink[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text("Visit Now"),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compacted Image
                imageURL.isNotEmpty
                    ? Image.network(
                      imageURL,
                      width: double.infinity,
                      height: 200, // Reduced from 300 to 200 for compactness
                      fit: BoxFit.cover,
                    ).animate().fadeIn(duration: 1.seconds)
                    : Container(
                      width: double.infinity,
                      height: 200, // Match compacted height
                      color: Colors.pink[100],
                    ),
                // Description
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                  ).animate().fadeIn(duration: 1.seconds),
                ),
                // Explorers count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Explorers: $views",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Video Player
                if (isVideoInitialized)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 30,
                              ),
                              onPressed: () {
                                setState(() {
                                  _videoController!.value.isPlaying
                                      ? _videoController!.pause()
                                      : _videoController!.play();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.pink, Colors.white, Colors.yellow],
            ),
          ),
        ],
      ),
    );
  }
}
