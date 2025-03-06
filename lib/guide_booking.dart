import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingPage extends StatefulWidget {
  final String guideId;
  final String destination;

  const BookingPage({required this.guideId, required this.destination});

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _bookGuide() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please log in and select a date")));
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': user.uid,
      'guideId': widget.guideId,
      'destination': widget.destination,
      'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guide booked successfully!")));
    Navigator.popUntil(context, (route) => route.isFirst); // Return to Home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book a Guide")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              title: Text(selectedDate == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(selectedDate!)),
              leading: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _bookGuide,
              child: const Text("Confirm Booking"),
            ),
          ],
        ),
      ),
    );
  }
}