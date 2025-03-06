// lib/screens/personalized_packages_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'travel_models.dart';
import 'package_detail_page.dart';
import 'custom_booking_history.dart';

class PersonalizedPackagesScreen extends StatelessWidget {
  final String userId;

  PersonalizedPackagesScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Travel Packages'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('personalized_packages')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
              ),
            );
          }
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No packages found.'));
          }

          final packages = snapshot.data!.docs.map((doc) {
            print('Processing doc: ${doc.data()}');
            return TravelPackage.fromJson(doc.data() as Map<String, dynamic>);
          }).toList();

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final pkg = packages[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.destination,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Duration: ${pkg.duration} days', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 8),
                      Text('Highlights:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('  - ${pkg.itinerary.values.first.first}'),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0, // Horizontal spacing between buttons
                        runSpacing: 8.0, // Vertical spacing if wrapped
                        alignment: WrapAlignment.end, // Align buttons to the end
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => PackageDetailScreen(package: pkg)),
                            ),
                            child: Text('Detail'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                              textStyle: TextStyle(fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final booking = Booking(
                                userId: userId,
                                package: pkg,
                                bookedAt: DateTime.now().toIso8601String(),
                              );
                              await FirebaseFirestore.instance.collection('booking_history').add(booking.toJson());
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => BookingHistoryScreen(userId: userId)),
                              );
                            },
                            child: Text('Book Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced padding
                              textStyle: TextStyle(fontSize: 14),
                            ),
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
      ),
    );
  }
}