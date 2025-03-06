import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'searched_reel_detail.dart';
import 'community_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;
  List<QueryDocumentSnapshot> _searchResults = [];
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _stopListeningAndSearch();
        }
        setState(() {
          _statusMessage = status;
        });
      },
      onError: (error) {
        setState(() {
          _statusMessage = "Error: ${error.errorMsg}";
        });
      },
    );

    if (!available) {
      setState(() {
        _statusMessage = "Speech recognition not available on this device.";
      });
    }
  }

  void _startListening() {
    if (!_speech.isAvailable) {
      setState(() {
        _statusMessage = "Speech recognition not available.";
      });
      return;
    }

    setState(() {
      _isListening = true;
      _statusMessage = "Listening...";
    });

    _speech.listen(
      onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
        });

        if (result.finalResult) {
          _stopListeningAndSearch();
        }
      },
    );
  }

  void _stopListeningAndSearch() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _statusMessage = "Processing search...";
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('reels')
            .where('caption', isGreaterThanOrEqualTo: query)
            .where('caption', isLessThanOrEqualTo: '$query\uf8ff')
            .get(),
        FirebaseFirestore.instance
            .collection('community_posts')
            .where('caption', isGreaterThanOrEqualTo: query)
            .where('caption', isLessThanOrEqualTo: '$query\uf8ff')
            .get(),
      ]);

      setState(() {
        _searchResults = [...results[0].docs, ...results[1].docs];
      });
    } catch (error) {
      setState(() {
        _statusMessage = "Error during search: $error";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToPost(QueryDocumentSnapshot post) {
    final collection = post.reference.parent.id;
    if (collection == 'reels') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchedReelDetail(reelId: post.id),
        ),
      );
    } else if (collection == 'community_posts') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityPage(
            highlightPostId: post.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _startListening,
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_statusMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No results found.'),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final post = _searchResults[index];
                  final caption = post['caption'] ?? 'No Caption Available';
                  final collection = post.reference.parent.id;
                  return ListTile(
                    title: Text(caption),
                    subtitle: Text('From: $collection'),
                    onTap: () => _navigateToPost(post),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
