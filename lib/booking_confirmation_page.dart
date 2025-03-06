import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart'; // Ensure this import is correct

class BookingConfirmationPage extends StatefulWidget {
  final String packageId;
  final double totalPrice;
  final String destination;
  final Map<int, List<Map<String, dynamic>>> selectedActivities;
  final Map<int, String> selectedTransportation;
  final Map<String, dynamic>? selectedHotel; // Now nullable

  const BookingConfirmationPage({
    super.key,
    required this.packageId,
    required this.totalPrice,
    required this.destination,
    required this.selectedActivities,
    required this.selectedTransportation,
    this.selectedHotel, // Optional, nullable
  });

  @override
  _BookingConfirmationPageState createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveBookingToHistory();
  }

  Future<void> _saveBookingToHistory() async {
    try {
      await FirebaseFirestore.instance.collection('booking_history').add({
        'packageId': widget.packageId,
        'destination': widget.destination,
        'totalPrice': widget.totalPrice,
        'selectedActivities': widget.selectedActivities,
        'selectedTransportation': widget.selectedTransportation,
        'selectedHotel':
        widget.selectedHotel ?? {}, // Default to empty map if null
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() => isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving booking: $e")));
      setState(() => isLoading = false);
    }
  }

  double _calculateBaseActivityPrice() {
    double activityPrice = 0.0;
    widget.selectedActivities.forEach((day, activities) {
      for (var activity in activities) {
        activityPrice += (activity['price'] as num? ?? 0).toDouble();
      }
    });
    return activityPrice;
  }

  double _calculateTransportationPrice() {
    double transportPrice = 0.0;
    widget.selectedTransportation.forEach((day, option) {
      switch (option) {
        case "Private Car":
          transportPrice += 500.0;
          break;
        case "Public Transport":
          transportPrice += 100.0;
          break;
        case "Walking":
        default:
          transportPrice += 0.0;
      }
    });
    return transportPrice;
  }

  double _calculateHotelPrice() {
    if (widget.selectedHotel == null || widget.selectedHotel!.isEmpty) {
      return 0.0;
    }
    return (widget.selectedHotel!['price'] as num? ?? 0).toDouble() *
        widget.selectedActivities.length; // Assuming days = activity days
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Booking Confirmation"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body:
      isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    "Trip Confirmed!",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Your Booking Details",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                _infoRow("Destination", widget.destination),
                _infoRow(
                  "Total Price",
                  "₹${widget.totalPrice.toStringAsFixed(2)}",
                ),
                const SizedBox(height: 20),
                const Text(
                  "Itinerary",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                ...widget.selectedActivities.entries.map((entry) {
                  final day = entry.key;
                  final activities = entry.value;
                  return ExpansionTile(
                    title: Text("Day $day"),
                    subtitle: Text(
                      "Transport: ${widget.selectedTransportation[day] ?? 'Not Selected'}",
                    ),
                    children:
                    activities.map((activity) {
                      return ListTile(
                        leading: Image.network(
                          activity['image'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                          const Icon(Icons.error),
                        ),
                        title: Text(activity['title'] ?? 'Unknown'),
                        subtitle: Text(
                          "₹${activity['price'] ?? 0} - ${activity['duration'] ?? 0} mins",
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
                const SizedBox(height: 20),
                const Text(
                  "Selected Hotel",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                if (widget.selectedHotel != null &&
                    widget.selectedHotel!.isNotEmpty)
                  ListTile(
                    leading: Image.network(
                      widget.selectedHotel!['image'] ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                      const Icon(Icons.error),
                    ),
                    title: Text(
                      widget.selectedHotel!['name'] ?? 'Unknown',
                    ),
                    subtitle: Text(
                      "₹${widget.selectedHotel!['price'] ?? 0} x ${widget.selectedActivities.length} nights",
                    ),
                  )
                else
                  const ListTile(
                    title: Text("No hotel selected"),
                    subtitle: Text(
                      "Hotel not included in this booking",
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  "Price Breakdown",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Divider(height: 20, thickness: 1),
                _priceRow("Activities", _calculateBaseActivityPrice()),
                _priceRow(
                  "Transportation",
                  _calculateTransportationPrice(),
                ),
                _priceRow("Hotel", _calculateHotelPrice()),
                const Divider(height: 20, thickness: 1),
                _priceRow("Total", widget.totalPrice, isTotal: true),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Confirm Booking",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            "₹${price.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
              color: isTotal ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
