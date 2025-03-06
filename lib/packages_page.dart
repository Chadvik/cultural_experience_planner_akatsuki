import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'itinerary_page.dart'; // Updated import

class PackagesPage extends StatelessWidget {
  final String destination;

  const PackagesPage({
    super.key,
    required this.destination,
    required int adults,
    required int children,
    required int budgetMin,
    required int budgetMax,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trip Packages for $destination"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream:
          FirebaseFirestore.instance
              .collection("travel_package") // Changed to singular
              .where("destination", isEqualTo: destination)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text("No packages available for $destination"),
              );
            }

            var packages = snapshot.data!.docs;

            return ListView.builder(
              itemCount: packages.length,
              itemBuilder: (context, index) {
                var package = packages[index];
                return Container(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ), // Typo: should be 'bottom'
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Package Image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            package["imageUrl"] ?? '',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.broken_image,
                                size: 50,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${package["days"]}N/${package["nights"]}D ${package["destination"]}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹${package["base_price"] ?? 0} / person",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  print(
                                    "Navigating to ItineraryPage with packageId: ${package.id}",
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ItineraryPage(
                                        packageId:
                                        package
                                            .id, // Should be 'package1'
                                        destination: package['destination'],
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("Explore"),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
