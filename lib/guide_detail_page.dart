import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'message_screen.dart'; // Import the MessageScreen
import 'guide_booking.dart';

class GuideDetailPage extends StatefulWidget {
  final String guideId;

  const GuideDetailPage({required this.guideId});

  @override
  _GuideDetailPageState createState() => _GuideDetailPageState();
}

class _GuideDetailPageState extends State<GuideDetailPage> {
  late VideoPlayerController _controller;
  bool _isChatActive = false;
  int? _userRating;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(''));
    _loadGuideData();
    _checkBookingStatus();
  }

  Future<void> _loadGuideData() async {
    final doc = await FirebaseFirestore.instance.collection('guides').doc(widget.guideId).get();
    if (doc.exists && mounted) {
      setState(() {
        _controller = VideoPlayerController.networkUrl(Uri.parse(doc['introVideoUrl'] ?? ''));
        _controller.initialize().then((_) => setState(() => _controller.play()));
      });
    }
  }

  Future<void> _checkBookingStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final booking = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('guideId', isEqualTo: widget.guideId)
          .where('isCompleted', isEqualTo: true)
          .where('rating', isNull: true)
          .get();
      if (booking.docs.isNotEmpty && mounted) {
        _showRatingDialog();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rate Your Experience", style: TextStyle(fontWeight: FontWeight.bold)),
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

    final booking = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('guideId', isEqualTo: widget.guideId)
        .where('isCompleted', isEqualTo: true)
        .where('rating', isNull: true)
        .get();

    if (booking.docs.isNotEmpty) {
      final bookingId = booking.docs.first.id;
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'rating': _userRating,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      final guideRef = FirebaseFirestore.instance.collection('guides').doc(widget.guideId);
      await guideRef.update({
        'points': FieldValue.increment(_userRating!),
        'ratingCount': FieldValue.increment(1),
        'rating': FieldValue.increment(_userRating! / 5), // Adjust average rating
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rating submitted successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guide Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.teal[800],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[800]!, Colors.teal[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView( // Prevent bottom overflow
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('guides').doc(widget.guideId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal)));
            }
            var guide = snapshot.data!;
            final name = guide['name'] ?? 'Unknown Guide';
            final expertise = guide['expertise'] ?? 'General Expertise';
            final rating = guide['rating']?.toStringAsFixed(1) ?? 'N/A';
            final points = guide['points'] is int
                ? guide['points'] as int
                : int.tryParse(guide['points']?.toString() ?? '0') ?? 0;
            final stars = points ~/ 300;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: guide['profileImageUrl'] != null
                          ? Image.network(
                        guide['profileImageUrl'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildAvatar(name),
                      )
                          : _buildAvatar(name),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expertise,
                            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                "Rating: $rating",
                                style: const TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: List.generate(
                                  stars,
                                      (index) => const Icon(Icons.star_border, color: Colors.teal, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Video Section
                _controller.value.isInitialized
                    ? Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.teal[700],
                            size: 32,
                          ),
                          onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                        ),
                      ],
                    ),
                  ],
                )
                    : const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal))),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MessageScreen(
                              chatId: "guide_${widget.guideId}_${FirebaseAuth.instance.currentUser!.uid}",
                              receiverId: widget.guideId,
                              receiverName: name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat, color: Colors.white),
                      label: const Text("Chat", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingPage(guideId: widget.guideId, destination: guide['destination']),
                          ),
                        );
                      },
                      icon: const Icon(Icons.book, color: Colors.white),
                      label: const Text("Book Guide", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Add padding at the bottom to prevent overflow
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.teal[700],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}