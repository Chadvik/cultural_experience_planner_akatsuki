import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GhoomarPage extends StatefulWidget {
  final String itemId;
  const GhoomarPage({Key? key, required this.itemId}) : super(key: key);

  @override
  State<GhoomarPage> createState() => _GhoomarPageState();
}

class _GhoomarPageState extends State<GhoomarPage> {
  VideoPlayerController? _videoController;
  AudioPlayer _audioPlayer = AudioPlayer();
  bool isVideoInitialized = false;
  Map<String, dynamic>? itemData;
  double _playbackSpeed = 1.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _fetchItemDetails() async {
    try {
      debugPrint('Fetching Ghoomar details for itemId: ${widget.itemId}');
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('ghoomar')
              .doc(widget.itemId)
              .get();
      if (snapshot.exists) {
        setState(() {
          itemData = snapshot.data() as Map<String, dynamic>;
          if (itemData?['videoURL']?.isNotEmpty ?? false) {
            _initializeVideo(itemData!['videoURL']);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No Ghoomar data found for ID: ${widget.itemId}';
        });
        debugPrint(_errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching Ghoomar details: $e';
      });
      debugPrint(_errorMessage);
    }
  }

  void _initializeVideo(String videoURL) {
    _videoController = VideoPlayerController.network(videoURL)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                isVideoInitialized = true;
              });
            }
          })
          .catchError((e) {
            debugPrint('Error initializing video: $e');
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

  void _playMusic() async {
    if (itemData?['audioURL'] != null) {
      await _audioPlayer.play(UrlSource(itemData!['audioURL']));
      await _audioPlayer.setPlaybackRate(_playbackSpeed);
    } else {
      debugPrint('No audio URL available');
    }
  }

  // Dance Steps Carousel (Fixed)
  Widget _buildDanceStepsCarousel() {
    List<dynamic> rawSteps =
        itemData?['danceSteps'] ??
        [
          {
            "title": "Step 1: The Twirl",
            "description": "Spin gracefully with hands raised.",
            "imageURL": "https://via.placeholder.com/150",
          },
          {
            "title": "Step 2: Footwork",
            "description": "Step in rhythm with the beat.",
            "imageURL": "https://via.placeholder.com/150",
          },
        ];

    List<Map<String, String>> steps =
        rawSteps.map((step) {
          return {
            "title": step["title"].toString(),
            "description": step["description"].toString(),
            "imageURL": step["imageURL"].toString(),
          };
        }).toList();

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: Image.network(
                    steps[index]['imageURL']!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => const Icon(Icons.error),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(
                        steps[index]['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        steps[index]['description']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideX(duration: 500.ms);
        },
      ),
    );
  }

  // Audio Player with Speed Control
  Widget _buildAudioPlayer() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _playMusic,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Play Ghoomar Music",
            style: TextStyle(fontSize: 16),
          ),
        ),
        Slider(
          min: 0.5,
          max: 2.0,
          value: _playbackSpeed,
          activeColor: Colors.orange,
          onChanged: (value) {
            setState(() => _playbackSpeed = value);
            _audioPlayer.setPlaybackRate(value);
          },
        ),
        Text(
          "Speed: ${_playbackSpeed.toStringAsFixed(1)}x",
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Gesture-Based Dance Practice
  Widget _buildDancePractice() {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nice twirl! Keep spinning!")),
          );
        } else if (details.primaryVelocity! < 0) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Great reverse twirl!")));
        }
      },
      child: Container(
        height: 100,
        color: Colors.orange[100],
        child: const Center(
          child: Text(
            "Swipe Left or Right to Practice Ghoomar Twirls",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ),
    );
  }

  // Community Dance Challenge
  Widget _buildChallengeSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            debugPrint("Record your Ghoomar! (Camera integration pending)");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            "Join the Ghoomar Challenge",
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('ghoomar_submissions')
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Colors.orange);
            }
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var submission = snapshot.data!.docs[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        submission['videoThumbnail'] ??
                            'https://via.placeholder.com/100',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.error),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // Trivia Popup
  Widget _buildTriviaButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Ghoomar Trivia"),
                content: Text(
                  itemData?['trivia']?[0] ??
                      "Ghoomar originated in Rajasthan as a dance for royalty.",
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Close",
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
        );
      },
      child: const Icon(Icons.info_outline, color: Colors.orange, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchItemDetails();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }
    if (itemData == null) {
      return Scaffold(body: const Center(child: Text("No data available")));
    }

    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(itemData!['imageURL']),
                  fit: BoxFit.cover,
                ),
              ),
            ).animate().rotate(duration: 5.seconds),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isVideoInitialized) ...[
                    AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _videoController?.seekTo(Duration.zero);
                        _videoController?.play();
                      },
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text(
                        "Join the Dance",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    itemData!['description'] ??
                        "Learn the graceful art of Ghoomar!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  _buildDanceStepsCarousel(),
                  const SizedBox(height: 20),
                  _buildAudioPlayer(),
                  const SizedBox(height: 20),
                  _buildDancePractice(),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _launchURL(itemData!['actionURL']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Learn More About Ghoomar",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildChallengeSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Ghoomar Trivia"),
                  content: Text(
                    itemData?['trivia']?[0] ??
                        "Ghoomar originated in Rajasthan as a dance for royalty.",
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
          );
        },
        backgroundColor: Colors.orange[600],
        child: const Icon(Icons.info, color: Colors.white),
      ),
    );
  }
}
