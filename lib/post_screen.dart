import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class PostScreen extends StatefulWidget {
  final String collection;
  const PostScreen({Key? key, required this.collection}) : super(key: key);

  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final TextEditingController _captionController = TextEditingController();
  XFile? _mediaFile; // This will store the selected image or video
  bool isImage = false; // To distinguish between image and video

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    if (widget.collection == 'community_posts') {
      // Allow only image selection for Community posts
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        _mediaFile = pickedImage;
        isImage = true;
      });
    } else {
      // Allow video selection for other collections like Reels
      final pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
      setState(() {
        _mediaFile = pickedVideo;
        isImage = false;
      });
    }
  }

  Future<String?> _uploadMediaToStorage() async {
    if (_mediaFile == null) {
      // No media selected
      return null;
    }

    try {
      // Get the file path from the selected media (image or video)
      File mediaFile = File(_mediaFile!.path);

      // Create a unique reference for the file in Firebase Storage
      String fileName = isImage
          ? 'images/${DateTime.now().millisecondsSinceEpoch}.jpg'
          : 'reels/${DateTime.now().millisecondsSinceEpoch}.mp4';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Upload the media file to Firebase Storage
      UploadTask uploadTask = storageRef.putFile(mediaFile);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL for the uploaded media
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading media: $e");
      return null;
    }
  }

  Future<void> _post() async {
    // Ensure caption is not empty for community posts
    if (_captionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please write a caption to post.')),
      );
      return;
    }

    try {
      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Upload media to Firebase Storage (if any) and get the URL
      String? mediaUrl = await _uploadMediaToStorage();

      // Save the post data to Firestore
      await FirebaseFirestore.instance.collection(widget.collection).add({
        'caption': _captionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous', // Optional user name
        'likes': widget.collection == 'reels' ? 0 : [], // Initialize likes: list for posts, 0 for reels
        if (widget.collection == 'community_posts') 'imageUrl': mediaUrl, // Add imageUrl if community_posts
        if (widget.collection == 'reels') 'videoUrl': mediaUrl, // Add videoUrl if reels
      });


      // After posting, return to the previous screen
      Navigator.pop(context);
    } catch (e) {
      print("Error posting: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create the post. Please try again.')),
      );
    }
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
            if (_mediaFile != null)
              Container(
                height: 200,
                child: isImage
                    ? Image.file(File(_mediaFile!.path)) // Show selected image
                    : Center(child: Text('Video Selected!')), // Placeholder for selected video
              ),
            TextField(
              controller: _captionController,
              decoration: InputDecoration(labelText: 'Write a caption...'),
            ),
            ElevatedButton(
              onPressed: _pickMedia,
              child: Text(
                widget.collection == 'community_posts'
                    ? 'Select Image (Optional)'
                    : 'Select Video',
              ),
            ),
            ElevatedButton(
              onPressed: _post,
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
