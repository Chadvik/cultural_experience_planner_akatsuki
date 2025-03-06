// lib/screens/booking_history_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'travel_models.dart';

class BookingHistoryScreen extends StatelessWidget {
  final String userId;

  BookingHistoryScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Booking History'), backgroundColor: Colors.deepPurple),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('booking_history')
            .where('userId', isEqualTo: userId)
            .orderBy('bookedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)));
          }
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text('No bookings found.'));

          final bookings = snapshot.data!.docs.map((doc) => Booking.fromJson(doc.data() as Map<String, dynamic>)).toList();

          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Text(booking.package.destination, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Booked on: ${booking.bookedAt}'),
                  trailing: Text('${booking.package.duration} days'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}