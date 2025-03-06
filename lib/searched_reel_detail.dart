import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchedReelDetail extends StatefulWidget {
  final String reelId;

  SearchedReelDetail({required this.reelId});

  @override
  _SearchedReelDetailState createState() => _SearchedReelDetailState();
}

class _SearchedReelDetailState extends State<SearchedReelDetail> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  VideoPlayerController? _videoController;
  String? _caption;

  @override
  void initState() {
    super.initState();
    _fetchReelDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _fetchReelDetails() async {
    try {
      // Fetch reel document from Firestore
      DocumentSnapshot reelSnapshot =
      await _firestore.collection('reels').doc(widget.reelId).get();

      if (reelSnapshot.exists) {
        final reelData = reelSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _caption = reelData['caption'];
          _videoController = VideoPlayerController.network(reelData['videoUrl'])
            ..initialize().then((_) {
              setState(() {});
              _videoController?.play();
            });
        });
      }
    } catch (e) {
      print("Error fetching reel details: $e");
    }
  }

  Future<void> _reportReel() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("User not logged in.");
        return;
      }

      final reelDoc = _firestore.collection('reels').doc(widget.reelId);
      final reelSnapshot = await reelDoc.get();

      if (reelSnapshot.exists) {
        // Increment the reportCount field in Firestore
        await reelDoc.update({
          'reportCount': FieldValue.increment(1),
        });
        print("Reel reported successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reported successfully.')),
        );
      }
    } catch (e) {
      print("Error reporting reel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reel Details"),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _reportReel();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'report',
                child: Text('Report this content'),
              ),
            ],
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _videoController != null && _videoController!.value.isInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_videoController!),
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                _caption ?? "",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
      )
          : Center(child: CircularProgressIndicator()),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:video_player/video_player.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// class SearchedReelDetail extends StatefulWidget {
//   final String reelId;
//
//   SearchedReelDetail({required this.reelId});
//
//   @override
//   _SearchedReelDetailState createState() => _SearchedReelDetailState();
// }
//
// class _SearchedReelDetailState extends State<SearchedReelDetail> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   VideoPlayerController? _videoController;
//   String? _caption;
//   bool _isLiked = false;
//   int _likeCount = 0;
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchReelDetails();
//   }
//
//   @override
//   void dispose() {
//     _videoController?.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchReelDetails() async {
//     try {
//       final reelDoc = await _firestore.collection('reels').doc(widget.reelId).get();
//
//       if (reelDoc.exists) {
//         final reelData = reelDoc.data() as Map<String, dynamic>;
//
//         setState(() {
//           _caption = reelData['caption'];
//           _likeCount = reelData['likes'] ?? 0;
//           _isLiked = reelData['likes']?.contains(_auth.currentUser?.uid) ?? false;
//
//           _videoController = VideoPlayerController.network(reelData['videoUrl'])
//             ..initialize().then((_) {
//               setState(() {
//                 _isLoading = false;
//               });
//               _videoController?.play();
//             });
//         });
//       } else {
//         throw "Reel not found.";
//       }
//     } catch (e) {
//       print("Error fetching reel details: $e");
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error loading reel details.")),
//       );
//     }
//   }
//
//   Future<void> _toggleLike() async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     final reelDoc = _firestore.collection('reels').doc(widget.reelId);
//     try {
//       if (_isLiked) {
//         await reelDoc.update({
//           'likes': FieldValue.increment(-1),
//           'likes': FieldValue.arrayRemove([user.uid]),
//         });
//         setState(() {
//           _isLiked = false;
//           _likeCount--;
//         });
//       } else {
//         await reelDoc.update({
//           'likes': FieldValue.increment(1),
//           'likes': FieldValue.arrayUnion([user.uid]),
//         });
//         setState(() {
//           _isLiked = true;
//           _likeCount++;
//         });
//       }
//     } catch (e) {
//       print("Error updating like: $e");
//     }
//   }
//
//   Future<void> _addComment(String comment) async {
//     final user = _auth.currentUser;
//     if (user == null) return;
//
//     try {
//       await _firestore
//           .collection('reels')
//           .doc(widget.reelId)
//           .collection('comments')
//           .add({
//         'text': comment,
//         'userId': user.uid,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Comment added!')),
//       );
//     } catch (e) {
//       print("Error adding comment: $e");
//     }
//   }
//
//   Future<void> _reportReel() async {
//     try {
//       final reelDoc = _firestore.collection('reels').doc(widget.reelId);
//       await reelDoc.update({
//         'reportCount': FieldValue.increment(1),
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Reel reported successfully.')),
//       );
//     } catch (e) {
//       print("Error reporting reel: $e");
//     }
//   }
//
//   void _shareReel() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Reel shared!')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Reel Details"),
//         actions: [
//           PopupMenuButton<String>(
//             onSelected: (value) {
//               if (value == 'report') {
//                 _reportReel();
//               }
//             },
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 value: 'report',
//                 child: Text('Report this content'),
//               ),
//             ],
//             icon: Icon(Icons.more_vert),
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : (_videoController != null && _videoController!.value.isInitialized)
//           ? Stack(
//         fit: StackFit.expand,
//         children: [
//           VideoPlayer(_videoController!),
//           Positioned(
//             bottom: 20,
//             left: 20,
//             child: Container(
//               width: MediaQuery.of(context).size.width * 0.8,
//               padding: EdgeInsets.all(8),
//               color: Colors.black54,
//               child: Text(
//                 _caption ?? "",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//                 maxLines: 2,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 80,
//             left: 20,
//             child: Row(
//               children: [
//                 IconButton(
//                   icon: Icon(
//                     _isLiked ? Icons.favorite : Icons.favorite_border,
//                     color: _isLiked ? Colors.red : Colors.white,
//                   ),
//                   onPressed: _toggleLike,
//                 ),
//                 Text(
//                   '$_likeCount',
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.comment, color: Colors.white),
//                   onPressed: () {
//                     showModalBottomSheet(
//                       context: context,
//                       builder: (context) {
//                         String comment = '';
//                         return Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               TextField(
//                                 decoration: InputDecoration(
//                                   labelText: 'Add a comment',
//                                 ),
//                                 onChanged: (value) {
//                                   comment = value;
//                                 },
//                               ),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   _addComment(comment);
//                                   Navigator.pop(context);
//                                 },
//                                 child: Text('Post'),
//                               ),
//                             ],
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 IconButton(
//                   icon: Icon(Icons.share, color: Colors.white),
//                   onPressed: _shareReel,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       )
//           : Center(child: Text('Error loading video.')),
//     );
//   }
// }

