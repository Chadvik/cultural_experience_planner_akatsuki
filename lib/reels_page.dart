import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'search_page.dart'; // Ensure this file exists

class ReelsPage extends StatefulWidget {
  final String? initialReelId;

  const ReelsPage({super.key, this.initialReelId});

  @override
  _ReelsPageState createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late PageController _pageController;
  late List<VideoPlayerController> _videoControllers;
  int _currentIndex = 0;
  bool _isInitialized = false;
  List<QueryDocumentSnapshot> _reels = [];
  final Map<String, bool> _likedReels = {};
  final Map<String, String> _userNames = {}; // Cache user names

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _videoControllers = [];
    _fetchReelsAndUserData(); // Fetch reels and user data together
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchReelsAndUserData() async {
    try {
      // Fetch reels
      final reelsSnapshot = await _firestore
          .collection('reels')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        _reels = reelsSnapshot.docs;
      });

      // Fetch user data for all unique userIds in reels
      final userIds = _reels.map((reel) => reel['userId'] as String).toSet();
      for (var userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _userNames[userId] = userData['name'] ?? 'Unknown User'; // Use 'name' field
        } else {
          _userNames[userId] = 'Unknown User';
        }
      }

      // Initialize videos after fetching data
      await _initializeVideos();
      _fetchLikedReels();
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reels: $e')),
      );
    }
  }

  Future<void> _initializeVideos() async {
    if (_reels.isEmpty) return;

    for (var reel in _reels) {
      final videoUrl = reel['videoUrl'] as String? ?? '';
      if (videoUrl.isEmpty) continue;

      final controller = VideoPlayerController.network(videoUrl)
        ..initialize().then((_) {
          setState(() {
            _isInitialized = true;
          });
        }).catchError((error) {
          print('Error initializing video: $error');
        });
      _videoControllers.add(controller);
    }

    if (widget.initialReelId != null) {
      final initialIndex = _reels.indexWhere((reel) => reel.id == widget.initialReelId);
      if (initialIndex != -1) {
        _pageController.jumpToPage(initialIndex);
        _currentIndex = initialIndex;
        if (_videoControllers.length > _currentIndex) {
          _videoControllers[_currentIndex].play();
        }
      }
    } else if (_videoControllers.isNotEmpty) {
      _videoControllers.first.play();
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index && _videoControllers.length > _currentIndex) {
      setState(() {
        _videoControllers[_currentIndex].pause();
        _currentIndex = index;
        if (_videoControllers.length > _currentIndex) {
          _videoControllers[_currentIndex].play();
        }
      });
    }
  }

  Future<void> _fetchLikedReels() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final likedReelsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('likedReels')
        .get();

    final likedReels = likedReelsSnapshot.docs.map((doc) => doc.id).toSet();
    setState(() {
      for (var reel in _reels) {
        final reelId = reel.id;
        _likedReels[reelId] = likedReels.contains(reelId);
      }
    });
  }

  Future<void> _handleLike(String reelId) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to like a reel.')),
      );
      return;
    }

    final userId = user.uid;
    final reelRef = _firestore.collection('reels').doc(reelId);
    final likesRef = reelRef.collection('likes').doc(userId);

    final likeSnapshot = await likesRef.get();
    if (!likeSnapshot.exists) {
      setState(() {
        _likedReels[reelId] = true;
      });
      await _firestore.runTransaction((transaction) async {
        final reelSnapshot = await transaction.get(reelRef);
        if (reelSnapshot.exists) {
          final currentLikes = reelSnapshot.data()?['likes'] ?? 0;
          transaction.update(reelRef, {'likes': currentLikes + 1});
          transaction.set(likesRef, {'likedAt': Timestamp.now()});
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('likedReels')
              .doc(reelId)
              .set({});
        }
      });
    }
  }

  void _handleDoubleTap(String reelId) {
    if (_likedReels[reelId] == true) return;
    _handleLike(reelId);
  }

  Future<void> _reportReel(String reelId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final reportsRef = _firestore
        .collection('reels')
        .doc(reelId)
        .collection('reports')
        .doc(user.uid);

    final reportSnapshot = await reportsRef.get();
    if (!reportSnapshot.exists) {
      await reportsRef.set({'reportedAt': Timestamp.now()});
      final reelRef = _firestore.collection('reels').doc(reelId);
      await reelRef.update({'reportCount': FieldValue.increment(1)});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Reels', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
      ),
      body: _reels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        onPageChanged: _onPageChanged,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          final reel = _reels[index];
          final reelId = reel.id;
          final reelData = reel.data() as Map<String, dynamic>;
          final videoUrl = reelData['videoUrl'] as String? ?? '';
          final caption = reelData['caption'] as String? ?? '';
          final likes = reelData['likes'] as int? ?? 0;
          final isLiked = _likedReels[reelId] ?? false;
          final userId = reelData['userId'] as String? ?? '';

          if (videoUrl.isEmpty || _videoControllers.length <= index ||
              !_videoControllers[index].value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onDoubleTap: () => _handleDoubleTap(reelId),
                child: VideoPlayer(_videoControllers[index]),
              ),
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            _userNames[userId]![0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _userNames[userId]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      caption,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 80,
                right: 20,
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.white,
                        size: 40,
                      ),
                      onPressed: () => _handleLike(reelId),
                    ),
                    Text(
                      "$likes",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.white, size: 40),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => CommentsSection(reelId: reelId),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, size: 40),
                      onPressed: () => Share.share('Check out this reel: $videoUrl'),
                    ),
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 40),
                      onPressed: () => _reportReel(reelId),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CommentsSection extends StatefulWidget {
  final String reelId;

  const CommentsSection({super.key, required this.reelId});

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _userNames = {}; // Cache user names for comments

  @override
  void initState() {
    super.initState();
    _fetchUserNames();
  }

  Future<void> _fetchUserNames() async {
    final commentsSnapshot = await _firestore
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments')
        .get();
    final userIds = commentsSnapshot.docs.map((doc) => doc['userId'] as String).toSet();

    for (var userId in userIds) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userNames[userId] = userData['name'] ?? 'Unknown User';
      } else {
        _userNames[userId] = 'Unknown User';
      }
    }
    setState(() {});
  }

  Future<void> _addComment(String comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in to comment.')),
      );
      return;
    }

    final commentsRef = _firestore
        .collection('reels')
        .doc(widget.reelId)
        .collection('comments');

    await commentsRef.add({
      'userId': user.uid,
      'comment': comment,
      'timestamp': Timestamp.now(),
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('reels')
                      .doc(widget.reelId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No comments yet.'));
                    }

                    final comments = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final commentData = comments[index].data() as Map<String, dynamic>;
                        final userId = commentData['userId'] as String;
                        final comment = commentData['comment'] as String;
                        final timestamp = (commentData['timestamp'] as Timestamp).toDate();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              _userNames[userId]![0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            _userNames[userId]!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(comment),
                          trailing: Text(
                            '${timestamp.hour}:${timestamp.minute}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        if (_commentController.text.isNotEmpty) {
                          _addComment(_commentController.text.trim());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}