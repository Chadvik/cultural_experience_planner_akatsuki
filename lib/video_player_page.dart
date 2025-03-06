import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({Key? key}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  double _videoProgress = 0.0;
  int _likeCount = 0;
  bool _isLiked = false;
  final TextEditingController _commentController = TextEditingController();

  String? userId;
  final String videoId = "awareness_theme_song";

  @override
  void initState() {
    super.initState();
    // Initialize video controller
    _controller =
    VideoPlayerController.asset('assets/awareness_video.mp4')
      ..addListener(() {
        setState(() {
          if (_controller.value.isInitialized) {
            _videoProgress =
                _controller.value.position.inMilliseconds.toDouble() /
                    _controller.value.duration.inMilliseconds.toDouble();
          }
        });
      })
      ..initialize().then((_) {
        setState(() {});
      });

    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final videoDoc = FirebaseFirestore.instance
        .collection('music_video')
        .doc(videoId);
    final videoSnapshot = await videoDoc.get();

    if (videoSnapshot.exists) {
      final data = videoSnapshot.data()!;
      setState(() {
        _likeCount = data['likeCount'] ?? 0;
        _isLiked = (data['likes'] ?? []).contains(userId);
      });
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  Future<void> _toggleLike() async {
    final videoDoc = FirebaseFirestore.instance
        .collection('music_video')
        .doc(videoId);

    if (_isLiked) {
      // Unlike the video
      await videoDoc.update({
        'likeCount': FieldValue.increment(-1),
        'likes': FieldValue.arrayRemove([userId]),
      });
      setState(() {
        _isLiked = false;
        _likeCount--;
      });
    } else {
      // Like the video
      await videoDoc.set({
        'likeCount': FieldValue.increment(1),
        'likes': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));
      setState(() {
        _isLiked = true;
        _likeCount++;
      });
    }
  }

  Future<void> _addComment() async {
    final comment = _commentController.text.trim();
    if (comment.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('music_video')
          .doc(videoId)
          .collection('comments')
          .add({
        'userId': userId,
        'comment': comment,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Awareness Theme Song')),
      body: Stack(
        children: [
          // Background Video
          Center(
            child:
            _controller.value.isInitialized
                ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
                : const CircularProgressIndicator(),
          ),
          // Overlay controls, progress bar, like, and comment
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress bar
                  Slider(
                    value: _videoProgress,
                    onChanged: (value) {
                      final newPosition = _controller.value.duration * value;
                      _controller.seekTo(newPosition);
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                  // Play/Pause/Volume controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: _togglePlayPause,
                        color: Colors.white,
                        iconSize: 40,
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop),
                        onPressed: () {
                          _controller.seekTo(Duration.zero);
                          _controller.pause();
                          setState(() {
                            _isPlaying = false;
                          });
                        },
                        color: Colors.white,
                        iconSize: 40,
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          setState(() {
                            _controller.setVolume(1.0);
                          });
                        },
                        color: Colors.white,
                        iconSize: 40,
                      ),
                    ],
                  ),
                  // Like and Comment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                        ),
                        onPressed: _toggleLike,
                        color: _isLiked ? Colors.red : Colors.white,
                        iconSize: 30,
                      ),
                      Text(
                        '$_likeCount Likes',
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.comment),
                        onPressed: () => _openCommentSheet(),
                        color: Colors.white,
                        iconSize: 30,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openCommentSheet() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
              ),
            ),
            ElevatedButton(
              onPressed: _addComment,
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}