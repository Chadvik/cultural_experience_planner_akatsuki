import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'day_details_page.dart';

class AddToItineraryPage extends StatefulWidget {
  final String modelName;
  final String guide;
  final String packageId; // Required existing packageId

  const AddToItineraryPage({
    super.key,
    required this.modelName,
    required this.guide,
    required this.packageId,
  });

  @override
  State<AddToItineraryPage> createState() => _AddToItineraryPageState();
}

class _AddToItineraryPageState extends State<AddToItineraryPage> {
  String? selectedCategory;
  int? selectedPrice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add to Itinerary"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Adding '${widget.modelName}' to Itinerary",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Guide: ${widget.guide}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Text(
              "Add as:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedCategory,
              hint: const Text("Select Category"),
              items:
              ['Activity', 'Hotel', 'Guide']
                  .map(
                    (category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ),
              )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Price:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: selectedPrice,
                  hint: const Text("Select Price"),
                  items:
                  [250, 350, 400]
                      .map(
                        (price) => DropdownMenuItem(
                      value: price,
                      child: Text("₹$price"),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPrice = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed:
              (selectedCategory == null || selectedPrice == null)
                  ? null
                  : () async {
                if (widget.packageId.isEmpty) {
                  print("Error: packageId is empty");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid package ID")),
                  );
                  return;
                }

                // Prepare the new activity data
                Map<String, dynamic> newItem = {
                  'title': widget.modelName,
                  'description': widget.guide,
                  'price': selectedPrice ?? 0,
                  'duration': 60,
                  'image':
                  'https://firebasestorage.googleapis.com/v0/b/thruthbridge.appspot.com/o/hawa_mahal%2Fhawa.jpeg?alt=media&token=ebd17030-a7cd-460e-9a12-d4e3beea76b1',
                };

                // Log the item being added
                print("Adding to Day 1: $newItem");

                // Prepare activities for DayDetailsPage
                Map<int, List<Map<String, dynamic>>> newActivities = {
                  1: [newItem],
                };

                // Attempt to update Firestore
                try {
                  DocumentReference dayRef = FirebaseFirestore.instance
                      .collection('travel_package')
                      .doc(widget.packageId)
                      .collection('itinerary')
                      .doc('day_1');

                  DocumentSnapshot daySnapshot = await dayRef.get();
                  List<Map<String, dynamic>> existingActivities = [];

                  if (daySnapshot.exists) {
                    Map<String, dynamic> data =
                    daySnapshot.data() as Map<String, dynamic>;
                    if (data['activities'] != null) {
                      existingActivities =
                      List<Map<String, dynamic>>.from(
                        data['activities'],
                      );
                    }
                  }

                  // Append the new activity
                  existingActivities.add(newItem);
                  newActivities[1] =
                      existingActivities; // Update for DayDetailsPage

                  await dayRef.set({
                    'activities': existingActivities,
                    'totalCost': FieldValue.increment(
                      selectedPrice ?? 0,
                    ),
                  }, SetOptions(merge: true));

                  print(
                    "Updated Firestore with activities: $existingActivities",
                  );
                } catch (e) {
                  print("Error updating Firestore: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Failed to save to Firestore: $e"),
                    ),
                  );
                }

                // Navigate to DayDetailsPage regardless of Firestore success
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => DayDetailsPage(
                      packageId: widget.packageId,
                      day: 1,
                      selectedActivities: newActivities,
                      selectedTransportation: {},
                      onPriceUpdate: (double price) {
                        print(
                          "Price updated in DayDetailsPage by: $price",
                        );
                      },
                    ),
                  ),
                );

                // Return data to the previous screen
                Navigator.pop(context, {
                  'category': selectedCategory,
                  'modelName': widget.modelName,
                  'guide': widget.guide,
                  'price': selectedPrice,
                  'activities': newActivities,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text(
                "Confirm Addition",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}