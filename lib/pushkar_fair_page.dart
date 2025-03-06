import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class PushkarFairPage extends StatefulWidget {
  const PushkarFairPage({Key? key}) : super(key: key);

  @override
  State<PushkarFairPage> createState() => _PushkarFairPageState();
}

class _PushkarFairPageState extends State<PushkarFairPage> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  ConfettiController? _confettiController;
  bool isVideoInitialized = false;
  bool isAudioPlaying = false;
  Map<String, dynamic>? itemData;
  bool _camelsVisible = false;

  // Audio position tracking
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 10),
    )..play();
    _fetchItemDetails();

    // Initialize audio player and listen to position/duration changes
    _audioPlayer = AudioPlayer();
    _audioPlayer!.onPositionChanged.listen((position) {
      setState(() {
        _audioPosition = position;
      });
    });
    _audioPlayer!.onDurationChanged.listen((duration) {
      setState(() {
        _audioDuration = duration;
      });
    });
    _audioPlayer!.onPlayerStateChanged.listen((state) {
      setState(() {
        isAudioPlaying = state == PlayerState.playing;
      });
    });
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
              .collection('pushkar_fair')
              .where('title', isEqualTo: 'Pushkar Fair')
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          itemData = snapshot.docs.first.data() as Map<String, dynamic>;
        });
        if (itemData?['videoURL']?.isNotEmpty ?? false) {
          _initializeVideo(itemData!['videoURL']);
        }
        _incrementViews(snapshot.docs.first.id);
      } else {
        debugPrint(
          'No document found for Pushkar Fair in pushkar_fair collection',
        );
      }
    } catch (e) {
      debugPrint('Error fetching Pushkar Fair details: $e');
    }
  }

  void _initializeVideo(String videoURL) {
    _videoController = VideoPlayerController.network(videoURL)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            isVideoInitialized = true;
          });
        }
      });
  }

  void _incrementViews(String docId) async {
    if (itemData == null) return;
    DocumentReference ref = FirebaseFirestore.instance
        .collection('pushkar_fair')
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
    } else {
      debugPrint('Could not launch URL: $url');
    }
  }

  void _rideCamel() async {
    print('Ride a Camel button pressed'); // Debug: Confirm button press
    try {
      String audioUrl =
          itemData?['audioURL'] ??
          "https://www.soundjay.com/buttons/bell-ring-01a.mp3";
      print('Playing audio from: $audioUrl'); // Debug: Confirm URL
      await _audioPlayer!.play(UrlSource(audioUrl));
      print('Audio playback started'); // Debug: Confirm audio success
    } catch (e) {
      print('Error playing audio: $e'); // Debug: Catch audio errors
    }
    setState(() {
      _camelsVisible = true;
      print('Camels visibility set to true'); // Debug: Confirm state change
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _camelsVisible = false;
          print('Camels visibility set to false'); // Debug: Confirm timeout
        });
      }
    });
  }

  void _toggleVideoPlayPause() {
    setState(() {
      _videoController!.value.isPlaying
          ? _videoController!.pause()
          : _videoController!.play();
    });
  }

  void _toggleAudioPlayPause() async {
    if (isAudioPlaying) {
      await _audioPlayer?.pause();
    } else {
      await _audioPlayer?.play(
        UrlSource(
          itemData!['audioURL'] ??
              "https://www.soundjay.com/buttons/bell-ring-01a.mp3",
        ),
      );
    }
    setState(() => isAudioPlaying = !isAudioPlaying);
  }

  void _seekAudio(double seconds) {
    _audioPlayer?.seek(Duration(seconds: seconds.toInt()));
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (itemData == null) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    String title = itemData!['title'] ?? "Pushkar Fair";
    String description =
        itemData!['description'] ?? "Experience the vibrant Pushkar Fair!";
    String imageURL = itemData!['imageURL'] ?? "";
    int views = itemData!['views'] ?? 0;
    String actionURL =
        itemData!['actionURL'] ?? "https://example.com/join-pushkar-fair";

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ).animate().slideX(duration: 500.ms),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 6,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ElevatedButton(
                  onPressed: _rideCamel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange[800],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    "Ride a Camel",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: ElevatedButton(
                  onPressed: () => _launchURL(actionURL),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.orange[800],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    "Join the Fair",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image at the top
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child:
                          imageURL.isNotEmpty
                              ? Image.network(
                                imageURL,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ).animate().fadeIn(duration: 1.seconds)
                              : Container(
                                width: double.infinity,
                                height: 180,
                                color: Colors.orange[100],
                              ),
                    ),
                  ),
                ),
                // Header with Description and Visitors
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Roboto',
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ).animate().fadeIn(duration: 1.seconds),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "$views",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Video Player Section with Audio Controls Above
                if (isVideoInitialized)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Audio Controls Spanning Full Width
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _toggleAudioPlayPause,
                                icon: Icon(
                                  isAudioPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  isAudioPlaying ? "Pause Audio" : "Play Audio",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[600],
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _formatDuration(_audioPosition),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "/ ${_formatDuration(_audioDuration)}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: _audioPosition.inSeconds.toDouble(),
                                min: 0.0,
                                max:
                                    _audioDuration.inSeconds.toDouble() > 0
                                        ? _audioDuration.inSeconds.toDouble()
                                        : 1.0,
                                onChanged: (value) {
                                  _seekAudio(value);
                                },
                                activeColor: Colors.orange[600],
                                inactiveColor: Colors.grey[300],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Video Player Below
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _toggleVideoPlayPause,
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            size: 24,
                            color: Colors.white,
                          ),
                          label: Text(
                            _videoController!.value.isPlaying
                                ? "Pause Video"
                                : "Play Video",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Camel Animation with Provided Logic (5 camels in vertical line)
          if (_camelsVisible)
            Positioned.fill(
              child: Stack(
                children: List.generate(5, (index) {
                  return AnimatedPositioned(
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeInOut,
                    left: _camelsVisible ? (index * 90 + 20).toDouble() : -60,
                    top: (MediaQuery.of(context).size.height / 6) * (index + 1),
                    child: const Text(
                          '🐫', // Camel emoji
                          style: TextStyle(fontSize: 50),
                        )
                        .animate()
                        .moveX(end: 450, duration: 3.seconds)
                        .fadeIn(duration: 500.ms)
                        .fadeOut(delay: 2.5.seconds),
                  );
                }),
              ),
            ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController!,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [Colors.orange, Colors.yellow, Colors.pink],
            ),
          ),
        ],
      ),
    );
  }
}
