import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DalBaatiChurmaPage extends StatefulWidget {
  final String? itemId;
  const DalBaatiChurmaPage({Key? key, this.itemId}) : super(key: key);

  @override
  State<DalBaatiChurmaPage> createState() => _DalBaatiChurmaPageState();
}

class _DalBaatiChurmaPageState extends State<DalBaatiChurmaPage> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool isVideoInitialized = false;
  Map<String, dynamic>? itemData;
  bool _camelsVisible = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _fetchItemDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _fetchItemDetails() async {
    try {
      if (widget.itemId != null && widget.itemId!.isNotEmpty) {
        DocumentSnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('dal_baati_churma')
                .doc(widget.itemId)
                .get();

        if (snapshot.exists) {
          setState(() {
            itemData = snapshot.data() as Map<String, dynamic>;
          });
          if (itemData?['videoURL']?.isNotEmpty ?? false) {
            _initializeVideo(itemData!['videoURL']);
          }
          _incrementViews(snapshot.id);
        }
      } else {
        QuerySnapshot snapshot =
            await FirebaseFirestore.instance
                .collection('dal_baati_churma')
                .where('title', isEqualTo: 'Dal Baati Churma')
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
        }
      }
    } catch (e) {
      debugPrint('Error fetching Dal Baati Churma details: $e');
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

  void _incrementViews(String docId) async {
    if (itemData == null) return;
    DocumentReference ref = FirebaseFirestore.instance
        .collection('dal_baati_churma')
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

  void _tasteIt() async {
    print('Taste It pressed');
    try {
      String audioUrl =
          itemData?['audioURL'] ??
          "https://www.soundjay.com/buttons/bell-ring-01a.mp3";
      await _audioPlayer!.play(UrlSource(audioUrl));
    } catch (e) {
      print('Error playing audio: $e');
    }
    setState(() => _camelsVisible = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _camelsVisible = false);
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

  @override
  Widget build(BuildContext context) {
    if (itemData == null) {
      return Scaffold(
        body: const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    String title = itemData!['title'] ?? "Dal Baati Churma";
    String description =
        itemData!['description'] ?? "A delicious Rajasthani delicacy!";
    String imageURL = itemData!['imageURL'] ?? "";
    int views = itemData!['views'] ?? 0;
    String actionURL =
        itemData!['actionURL'] ?? "https://example.com/order-dal-baati-churma";
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.orange[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageURL),
                      fit: BoxFit.cover,
                    ),
                  ),
                ).animate().fadeIn(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                          fontFamily: 'Roboto',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isVideoInitialized) ...[
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
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Roboto',
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Views: $views",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _tasteIt,
                        icon: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🍲', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 4),
                            Text('🍛', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 4),
                            Text('🍴', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        label: const Text(
                          "Taste It",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _launchURL(actionURL),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Order a Feast",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Top Restaurants in Rajasthan for Dal Baati Churma",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          _buildRestaurantCard(
                            name: "Chokhi Dhani, Jaipur",
                            rating: "4.5/5",
                            imageUrl:
                                "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/12/11/4c/a4/main-entrance.jpg?w=1800&h=1000&s=1",
                            description:
                                "A village-themed experience with authentic Dal Baati Churma cooked over charcoal.",
                          ),
                          const SizedBox(height: 12),
                          _buildRestaurantCard(
                            name: "Santosh Bhojnalaya, Jaipur",
                            rating: "4.7/5",
                            imageUrl:
                                "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/07/8e/16/f4/santosh-bhojnalaya.jpg?w=800&h=500&s=1",
                            description:
                                "A local favorite serving crisp baatis with rich dal and churma.",
                          ),
                          const SizedBox(height: 12),
                          _buildRestaurantCard(
                            name: "Surya Mahal, Jodhpur",
                            rating: "4.4/5",
                            imageUrl:
                                "https://surya-mahal.hotels-rajasthan.com/data/Pics/OriginalPhoto/6497/649752/649752045/hotel-surya-mahal-beawar-pic-7.JPEG",
                            description:
                                "Ghee-laden Dal Baati Churma near Mehrangarh Fort.",
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_camelsVisible)
            Positioned.fill(
              child: Stack(
                children: List.generate(5, (index) {
                  return AnimatedPositioned(
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeInOut,
                    left: _camelsVisible ? (index * 90 + 20).toDouble() : -60,
                    top: (screenHeight / 6) * (index + 1),
                    child: const Text('🥗', style: TextStyle(fontSize: 50))
                        .animate()
                        .moveX(end: 450, duration: 3.seconds)
                        .fadeIn(duration: 500.ms)
                        .fadeOut(delay: 2.5.seconds),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard({
    required String name,
    required String rating,
    required String imageUrl,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rating: $rating",
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
