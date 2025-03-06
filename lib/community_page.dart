import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class CommunityPage extends StatefulWidget {
  final String? highlightPostId;

  const CommunityPage({this.highlightPostId});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _userNames = {}; // Cache user names
  List<QueryDocumentSnapshot> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPostsAndUserData();
  }

  Future<void> _fetchPostsAndUserData() async {
    try {
      // Fetch posts
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        _posts = postsSnapshot.docs;
      });

      // Fetch user data for all unique userIds in posts
      final userIds = _posts.map((post) => post['userId'] as String).toSet();
      for (var userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _userNames[userId] = userData['name'] ?? 'Anonymous'; // Use 'name' field
        } else {
          _userNames[userId] = 'Anonymous';
        }
      }
      setState(() {});
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading community posts: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Forum',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreatePostPage()),
            ),
          ),
        ],
      ),
      body: _posts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('community_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isHighlighted = post.id == widget.highlightPostId;
              return PostCard(
                post: post,
                isHighlighted: isHighlighted,
                userName: _userNames[post['userId']] ?? 'Anonymous',
              );
            },
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final QueryDocumentSnapshot post;
  final bool isHighlighted;
  final String userName;

  const PostCard({
    required this.post,
    required this.isHighlighted,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLiked = post['likes'].contains(user?.uid);
    final timestamp = post['timestamp']?.toDate();
    final formattedTimestamp =
    timestamp != null ? _formatTimestamp(timestamp) : 'Just now';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: isHighlighted ? Colors.yellow[100] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      userName.isNotEmpty ? userName[0] : '?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    formattedTimestamp,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey),
                    onPressed: () => _reportPost(post.id, context),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: Text(
                post['caption'] ?? '',
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(height: 8),
            if (post['imageUrl'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(post['imageUrl']!),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.favorite,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _toggleLike(post.id, isLiked),
                    ),
                    Text(
                      '${post['likes'].length}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: Icon(Icons.chat_bubble_outline, size: 20),
                  label: Text('Comment'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsPage(postId: post.id),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inDays > 0) {
      return DateFormat('MM/dd/yyyy').format(timestamp);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _toggleLike(String postId, bool isLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final postRef = FirebaseFirestore.instance.collection('community_posts').doc(postId);
    if (isLiked) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> _reportPost(String postId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        TextEditingController reasonController = TextEditingController();
        return AlertDialog(
          title: Text("Report Post"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for reporting',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isNotEmpty) {
                  FirebaseFirestore.instance.collection('reports').add({
                    'postId': postId,
                    'userId': user.uid,
                    'reason': reason,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Post reported successfully.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide a reason.')),
                  );
                }
              },
              child: Text("Report"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}

class CreatePostPage extends StatefulWidget {
  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _captionController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
      });
    }
  }

  Future<void> _createPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? imageUrl;
    if (_image != null) {
      final storageRef =
      FirebaseStorage.instance.ref().child('post_images/${DateTime.now()}.jpg');
      await storageRef.putFile(_image!);
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('community_posts').add({
      'caption': _captionController.text,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'likes': [],
    });

    _captionController.clear();
    setState(() {
      _image = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post created successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: 'Write something...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            SizedBox(height: 16),
            if (_image != null)
              Column(
                children: [
                  Image.file(_image!, height: 200, fit: BoxFit.cover),
                  TextButton(
                    onPressed: () => setState(() => _image = null),
                    child: Text('Remove Image'),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Add Image'),
                  onPressed: _pickImage,
                ),
                ElevatedButton(
                  onPressed: _createPost,
                  child: Text('Post'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentsPage extends StatefulWidget {
  final String postId;

  const CommentsPage({required this.postId});

  @override
  _CommentsPageState createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
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
        .collection('community_posts')
        .doc(widget.postId)
        .collection('comments')
        .get();
    final userIds = commentsSnapshot.docs.map((doc) => doc['userId'] as String).toSet();

    for (var userId in userIds) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        _userNames[userId] = userData['name'] ?? 'Anonymous'; // Use 'name' field
      } else {
        _userNames[userId] = 'Anonymous';
      }
    }
    setState(() {});
  }

  Future<void> _addComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _commentController.text.isEmpty) return;

    await _firestore
        .collection('community_posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': _commentController.text,
      'userId': user.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('community_posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final userId = comment['userId'] as String;
                    final userName = _userNames[userId] ?? 'Anonymous';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          userName.isNotEmpty ? userName[0] : '?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(comment['text']),
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
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}