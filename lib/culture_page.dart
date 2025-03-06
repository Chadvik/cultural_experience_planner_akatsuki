import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dal_baati_churma_page.dart';
import 'bandhana_saree_page.dart';
import 'ghoomar_page.dart';
import 'hawa_mahal_page.dart';
import 'pushkar_fair_page.dart';

class CulturePage extends StatefulWidget {
  const CulturePage({super.key});

  @override
  _CulturePageState createState() => _CulturePageState();
}

class _CulturePageState extends State<CulturePage> {
  String? selectedState;
  Map<String, dynamic>? stateData;
  bool isLoading = false;
  String? errorMessage;

  void fetchCultureData(String state) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      var doc = await FirebaseFirestore.instance.collection('culture_data').doc(state).get();
      if (doc.exists) {
        setState(() {
          stateData = doc.data();
        });
      } else {
        setState(() {
          errorMessage = "No cultural data found for $state.";
          stateData = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: $e";
        stateData = null;
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Consistent with previous theme
      appBar: AppBar(
        title: const Text(
          "Explore Indian Culture",
          style: TextStyle(
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
      body: Column(
        children: [
          // Dropdown with enhanced styling
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: selectedState,
              hint: const Text("Select a State"),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: ["Rajasthan", "Kerala", "Tamil Nadu", "Maharashtra"]
                  .map((state) => DropdownMenuItem(value: state, child: Text(state)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedState = value!;
                  fetchCultureData(value);
                });
              },
            ),
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
              ),
            ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          if (!isLoading && stateData != null)
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      buildCategory("Monuments", stateData!['monuments']),
                      buildCategory("Food", stateData!['food']),
                      buildCategory("Dance", stateData!['dance']),
                      buildCategory("Festivals", stateData!['festivals']),
                      buildCategory("Attire", stateData!['attire']),
                      buildVideos(stateData!['videos']),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildCategory(String title, List<dynamic>? items) {
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent[700],
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  if (title == "Monuments" && items[index]['name'] == "Hawa Mahal") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HawaMahalPage()),
                    );
                  } else if (title == "Festivals" && items[index]['name'] == "Pushkar Fair") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PushkarFairPage()),
                    );
                  } else if (title == "Food" && items[index]['name'] == "Dal Baati Churma") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DalBaatiChurmaPage(itemId: "dal_baati_churma_001"),
                      ),
                    );
                  } else if (title == "Dance" && items[index]['name'] == "Ghoomar") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GhoomarPage(itemId: "ghoomar_001"),
                      ),
                    );
                  } else if (title == "Attire" && items[index]['name'] == "Bandhani Saree") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BandhanaSareePage(itemId: "bandhana_001"),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            items[index]['image'],
                            height: 110,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 110,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            items[index]['name'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget buildVideos(List<dynamic>? videos) {
    if (videos == null || videos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            "Videos",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent[700],
            ),
          ),
        ),
        Column(
          children: videos.map((video) {
            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.video_library, color: Colors.blueAccent, size: 28),
                title: Text(
                  video['title'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.play_circle_outline, color: Colors.blueAccent),
                onTap: () async {
                  final Uri uri = Uri.parse(video['url']);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Could not launch ${video['url']}"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}