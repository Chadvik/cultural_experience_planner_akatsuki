import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ar_home_page.dart';
import 'booking_confirmation_page.dart';
import 'day_details_page.dart';

class ItineraryPage extends StatefulWidget {
  final String packageId;
  final String destination;

  const ItineraryPage({
    super.key,
    required this.packageId,
    required this.destination,
  });

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  int totalDays = 0;
  double totalPrice = 0.0;
  Map<int, List<Map<String, dynamic>>> selectedActivities = {};
  List<Map<String, dynamic>> availableHotels = [];
  Map<int, String> selectedTransportation = {};
  Map<String, dynamic>? selectedHotel;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPackageDetails();
  }

  Future<void> _fetchPackageDetails() async {
    setState(() => isLoading = true);
    try {
      final packageSnapshot =
      await FirebaseFirestore.instance
          .collection('travel_package')
          .doc(widget.packageId)
          .get();

      if (!packageSnapshot.exists) {
        _showErrorSnackBar("Package '${widget.packageId}' not found!");
        setState(() => isLoading = false);
        return;
      }

      setState(() {
        totalDays = packageSnapshot['days'] as int? ?? 0;
        totalPrice = (packageSnapshot['base_price'] as num? ?? 0).toDouble();
        isLoading = false;
      });
      await _fetchAvailableHotels();
    } catch (e) {
      _showErrorSnackBar("Network error: Please check your connection ($e)");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAvailableHotels() async {
    try {
      final hotelSnapshot =
      await FirebaseFirestore.instance
          .collection('travel_package')
          .doc(widget.packageId)
          .collection('hotels')
          .get();

      setState(() {
        availableHotels =
            hotelSnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
      });
    } catch (e) {
      _showErrorSnackBar("Error fetching hotels: $e");
    }
  }

  Future<void> _selectHotel() async {
    if (availableHotels.isEmpty) {
      _showErrorSnackBar("No hotels available");
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildHotelDialog(),
    );

    if (result != null && mounted) {
      setState(() {
        if (selectedHotel != null) {
          totalPrice -=
              (selectedHotel!['price'] as num? ?? 0).toDouble() * totalDays;
        }
        selectedHotel = result;
        totalPrice += (result['price'] as num? ?? 0).toDouble() * totalDays;
      });
    }
  }

  Widget _buildHotelDialog() {
    return AlertDialog(
      title: const Text("Select Hotel"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: availableHotels.length,
          itemBuilder: (context, index) {
            final hotel = availableHotels[index];
            return ListTile(
              leading: _buildHotelImage(hotel['image']),
              title: Text(hotel['name'] ?? 'Unknown Hotel'),
              subtitle: Text(
                "₹${hotel['price']?.toString() ?? '0'} per night - Rating: ${hotel['rating'] ?? 'N/A'}",
              ),
              onTap: () => Navigator.pop(context, hotel),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHotelImage(String? imageUrl) {
    return Image.network(
      imageUrl ?? '',
      width: 50,
      height: 50,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _updatePrice(double priceChange) {
    setState(() {
      totalPrice += priceChange;
    });
  }

  void _confirmBooking() {
    if (selectedHotel == null) {
      _showErrorSnackBar("Please select a hotel");
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => BookingConfirmationPage(
            packageId: widget.packageId,
            totalPrice: totalPrice,
            destination: widget.destination,
            selectedActivities: selectedActivities,
            selectedTransportation: selectedTransportation,
            selectedHotel: selectedHotel!,
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plan Your Trip to ${widget.destination}"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Go to AR Home',
            onPressed:
                () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ArHomePage(title: 'AR!'),
              ),
            ),
          ),
        ],
      ),
      body:
      isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: totalDays,
            itemBuilder: (context, index) {
              final day = index + 1;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Day $day"),
                  subtitle: Text(
                    selectedTransportation[day] ?? "No transport selected",
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap:
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DayDetailsPage(
                        packageId: widget.packageId,
                        day: day,
                        selectedActivities: selectedActivities,
                        selectedTransportation: selectedTransportation,
                        onPriceUpdate: _updatePrice,
                      ),
                    ),
                  ).then((_) => setState(() {})),
                ),
              );
            },
          ),
        ),
        _buildPriceAndBookingSection(),
      ],
    );
  }

  Widget _buildPriceAndBookingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Price:", style: TextStyle(fontSize: 18)),
              Text(
                "₹${totalPrice.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, color: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selectedHotel == null)
            ElevatedButton(
              onPressed: _selectHotel,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Select Hotel"),
            )
          else
            ListTile(
              leading: _buildHotelImage(selectedHotel!['image']),
              title: Text(selectedHotel!['name'] ?? 'Unknown'),
              subtitle: Text(
                "₹${selectedHotel!['price']?.toString() ?? '0'} x $totalDays nights",
              ),
              onTap: _selectHotel, // Allow changing hotel
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _confirmBooking,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.teal,
            ),
            child: const Text("Confirm Booking"),
          ),
        ],
      ),
    );
  }
}