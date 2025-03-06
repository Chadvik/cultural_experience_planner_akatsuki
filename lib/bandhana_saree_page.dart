import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BandhanaSareePage extends StatefulWidget {
  final String itemId;
  const BandhanaSareePage({Key? key, required this.itemId}) : super(key: key);

  @override
  State<BandhanaSareePage> createState() => _BandhanaSareePageState();
}

class _BandhanaSareePageState extends State<BandhanaSareePage> {
  VideoPlayerController? _videoController;
  Map<String, dynamic>? itemData;
  bool isVideoInitialized = false;
  int views = 0;
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
    super.dispose();
  }

  void _fetchItemDetails() async {
    try {
      DocumentSnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('bandhana_saree')
              .doc(widget.itemId)
              .get();
      if (snapshot.exists) {
        setState(() {
          itemData = snapshot.data() as Map<String, dynamic>;
          views = itemData!['views'] ?? 0;
          if (itemData?['videoURL']?.isNotEmpty ?? false) {
            _initializeVideo(itemData!['videoURL']);
          }
          _isLoading = false;
        });
        _incrementViews(snapshot.id);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No Bandhana Saree data found for ID: ${widget.itemId}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error fetching Bandhana Saree details: $e';
      });
    }
  }

  void _initializeVideo(String videoURL) {
    _videoController = VideoPlayerController.network(videoURL)
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                isVideoInitialized = true;
                _videoController!.setVolume(0.0); // Mute the video
                _videoController!.setLooping(true);
                _videoController!.play();
              });
            }
          })
          .catchError((e) {
            debugPrint('Error initializing video: $e');
          });
  }

  void _incrementViews(String docId) async {
    DocumentReference ref = FirebaseFirestore.instance
        .collection('bandhana_saree')
        .doc(docId);
    FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        int newViews = (snapshot['views'] ?? 0) + 1;
        transaction.update(ref, {'views': newViews});
      }
    });
    setState(() {
      views++;
    });
  }

  // Wrapping Steps Carousel
  Widget _buildWrappingSteps() {
    List<Map<String, String>> steps = [
      {
        "title": "Step 1: Start at the Waist",
        "description":
            "Tuck the saree end into your petticoat at the right waist.",
        "imageURL":
            "https://cdn.shopify.com/s/files/1/0220/5433/8656/files/01_4_480x480.jpg?v=1687158583",
      },
      {
        "title": "Step 2: Wrap Around",
        "description": "Wrap it around your waist once, keeping it even.",
        "imageURL":
            "https://cdn.shopify.com/s/files/1/0220/5433/8656/files/DSC_3114_480x480.jpg?v=1687157722",
      },
      {
        "title": "Step 3: Pleat the Pallu",
        "description": "Make 5-7 pleats and drape over your left shoulder.",
        "imageURL":
            "https://cdn.shopify.com/s/files/1/0220/5433/8656/files/DSC_3142_480x480.jpg?v=1687157968",
      },
    ];
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: steps.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Colors.orange[100],
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Image.network(
                    steps[index]['imageURL']!,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
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
                          color: Colors.deepOrange,
                        ),
                      ),
                      Text(
                        steps[index]['description']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0.0);
        },
      ),
    );
  }

  // Famous Shops Section
  Widget _buildFamousShops() {
    List<Map<String, String>> shops = [
      {"name": "Pratibha Sarees", "url": "https://www.pratibhasarees.com"},
      {"name": "Khatri Jamnadas", "url": "https://khatrijamnadas.com"},
      {"name": "Kalki Fashion", "url": "https://www.kalkifashion.com"},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Where to Buy Bandhani Sarees",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepOrange,
          ),
        ),
        const SizedBox(height: 10),
        ...shops.map(
          (shop) => ListTile(
            leading: const Icon(Icons.store, color: Colors.orange),
            title: Text(shop['name']!, style: const TextStyle(fontSize: 16)),
            onTap: () async {
              final Uri uri = Uri.parse(shop['url']!);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      ],
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
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
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
            // Header Image
            Container(
              height: 300,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(itemData!['imageURL']),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms),
            const SizedBox(height: 20),

            // Title and Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    itemData!['title'] ?? "Bandhani Saree",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    itemData!['description'] ??
                        "A timeless tie-dye masterpiece from Gujarat and Rajasthan.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Video Section
            if (isVideoInitialized) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "How to Wrap a Bandhani Saree",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],

            // Views Counter
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    "Views: $views",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Wrapping Steps
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Steps to Wrap Your Bandhani Saree",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildWrappingSteps(),
                ],
              ),
            ),

            // Famous Shops
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildFamousShops(),
            ),

            // Creative Idea: Pattern Animation
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Bandhani Pattern Magic",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          '●',
                          style: TextStyle(fontSize: 20, color: Colors.orange),
                        ),
                      ).animate().scale(
                        duration: 1000.ms,
                        delay: Duration(milliseconds: 200 * index),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Watch the tie-dye dots come to life!",
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
