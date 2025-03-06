import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'guide_detail_page.dart';

class GuidesListPage extends StatelessWidget {
  final String destination;

  const GuidesListPage({required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Local Guides in $destination",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent[700],
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent[700]!, Colors.blueAccent[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('guides')
            .where('destination', isEqualTo: destination)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_search, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No guides found in $destination",
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var guides = snapshot.data!.docs;
          return SingleChildScrollView(
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: guides.length,
                  itemBuilder: (context, index) {
                    return GuideCard(guide: guides[index]);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GuideCard extends StatelessWidget {
  final QueryDocumentSnapshot guide;

  const GuideCard({required this.guide});

  @override
  Widget build(BuildContext context) {
    final name = guide['name'] ?? 'Unknown Guide';
    final expertise = guide['expertise'] ?? 'General Expertise';
    final rating = guide['rating']?.toStringAsFixed(1) ?? 'N/A';
    final profileImageUrl = guide['profileImageUrl'] as String?;
    final monumentImageUrl = guide['monumentImageUrl'] as String?; // New field for monument image
    final pointsRaw = guide['points'];
    print('Points raw value for $name: $pointsRaw, Type: ${pointsRaw.runtimeType}');

    final points = _parsePoints(pointsRaw) ?? 0;
    final stars = points ~/ 300;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuideDetailPage(guideId: guide.id)),
      ),
      child: Card(
        elevation: 8, // Slightly higher elevation for depth
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Profile Image and Guide Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? Image.network(
                      profileImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildAvatar(name),
                    )
                        : _buildAvatar(name),
                  ),
                  const SizedBox(width: 16),
                  // Guide Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expertise,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
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
                                    (index) => const Icon(Icons.star_border,
                                    color: Colors.blueAccent, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Monument Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: monumentImageUrl != null && monumentImageUrl.isNotEmpty
                    ? Image.network(
                  monumentImageUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.account_balance,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : Container(
                  width: double.infinity,
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.account_balance,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Contact Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Contact $name"),
                        backgroundColor: Colors.blueAccent[100],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 4,
                  ),
                  child: const Text(
                    "Contact",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _parsePoints(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }
    return 0;
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blueAccent[700],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}