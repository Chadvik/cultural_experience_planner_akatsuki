import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // For picking profile photos
import 'dart:io'; // For handling files
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'post_screen.dart'; // Import PostScreen for creating posts/reels
import 'searched_reel_detail.dart'; // Ensure this file exists

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String userId;
  int postCount = 0;
  Map<String, dynamic>? userData;
  File? _profileImage; // To store the locally picked profile image

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
        });
      }

      final reelsSnapshot = await _firestore
          .collection('reels')
          .where('userId', isEqualTo: userId)
          .get();
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .get();

      setState(() {
        postCount = reelsSnapshot.docs.length + postsSnapshot.docs.length;
      });
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Future<void> _pickProfileImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfileImage(pickedFile.path);
    }
  }

  Future<void> _uploadProfileImage(String imagePath) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${user.uid}.jpg');
      await storageRef.putFile(File(imagePath));

      final downloadURL = await storageRef.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'profilePictureUrl': downloadURL,
      });

      setState(() {
        userData!['profilePictureUrl'] = downloadURL;
        _profileImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated successfully!')),
      );
    } catch (e) {
      print('Error uploading profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile photo: $e')),
      );
    }
  }

  void _navigateToPostScreen(String collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(collection: collection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        // title: const Text(
        //   "Bharat Yatra",
        //   style: TextStyle(color: Colors.white),
        // ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!) as ImageProvider
                            : (userData!['profilePictureUrl'] != null
                            ? NetworkImage(userData!['profilePictureUrl'])
                            : const AssetImage('assets/profile_picture.png')
                        as ImageProvider),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userData!['name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userData!['email'] ?? '',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatColumn('Posts', postCount.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _navigateToPostScreen('community_posts');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            // Implement share profile functionality
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("Share Profile"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tabs for Posts and Reels
              DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.blue[900],
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue[900],
                      tabs: [
                        Tab(icon: Icon(Icons.grid_on), text: "Posts"),
                        Tab(icon: Icon(Icons.video_library), text: "Reels"),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: TabBarView(
                        children: [
                          _buildPostsSection(),
                          _buildReelsSection(),
                        ],
                      ),
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

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildPostsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading posts: ${snapshot.error.toString().contains('failed-precondition') ? 'Index required. Please check Firebase Console.' : snapshot.error}",
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No posts available."));
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final timestamp = post['timestamp'] as Timestamp?;
            final caption = post['caption'] as String? ?? '';
            final imageUrl = post['imageUrl'] as String?;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('assets/profile_picture.png'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData!['name'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                timestamp != null
                                    ? timeAgo(timestamp.toDate())
                                    : "Just now",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(caption),
                    if (imageUrl != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Image failed to load'),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.comment_outlined),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReelsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reels')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading reels: ${snapshot.error.toString().contains('failed-precondition') ? 'Index required. Please check Firebase Console.' : snapshot.error}",
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No reels available."));
        }

        final reels = snapshot.data!.docs;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 0.7,
          ),
          itemCount: reels.length,
          itemBuilder: (context, index) {
            final reel = reels[index].data() as Map<String, dynamic>;
            final reelId = reels[index].id;
            final caption = reel['caption'] as String? ?? '';
            final timestamp = reel['timestamp'] as Timestamp?;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchedReelDetail(reelId: reelId),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.black54,
                        child: Text(
                          caption.length > 20 ? '${caption.substring(0, 20)}...' : caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String timeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inHours < 1) return '${duration.inMinutes}m ago';
    if (duration.inDays < 1) return '${duration.inHours}h ago';
    if (duration.inDays < 7) return '${duration.inDays}d ago';
    if (duration.inDays < 30) return '${(duration.inDays / 7).floor()}w ago';
    return '${(duration.inDays / 30).floor()}m ago';
  }
}