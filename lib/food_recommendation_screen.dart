import 'package:flutter/material.dart';
import 'firestore_service.dart';

class FoodRecommendationScreen extends StatefulWidget {
  @override
  _FoodRecommendationScreenState createState() => _FoodRecommendationScreenState();
}

class _FoodRecommendationScreenState extends State<FoodRecommendationScreen> {
  List<Map<String, dynamic>> dishes = [];
  String? selectedRegion;
  String? selectedFlavor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialDishes();
  }

  Future<void> _fetchInitialDishes() async {
    try {
      // Fetch all dishes initially (or filter by default if needed)
      List<Map<String, dynamic>> fetchedDishes =
      await FirestoreService.fetchDishes(region: null, flavorProfile: null);
      setState(() {
        dishes = fetchedDishes;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching dishes: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDishes() async {
    if (selectedRegion == null && selectedFlavor == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      List<Map<String, dynamic>> fetchedDishes =
      await FirestoreService.fetchDishes(region: selectedRegion, flavorProfile: selectedFlavor);
      setState(() {
        dishes = fetchedDishes;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching dishes: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Taste the Tradition",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange[100]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Dropdowns with Styling
              _buildDropdown(
                hint: "Select Region",
                value: selectedRegion,
                items: ["North", "West", "East", "South"],
                onChanged: (value) {
                  setState(() {
                    selectedRegion = value;
                    _fetchDishes();
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                hint: "Select Flavor Profile",
                value: selectedFlavor,
                items: ["sweet", "spicy", "savory"],
                onChanged: (value) {
                  setState(() {
                    selectedFlavor = value;
                    _fetchDishes();
                  });
                },
              ),
              const SizedBox(height: 24),
              // Loading Indicator or Dish List
              if (isLoading)
                Center(
                  child: CircularProgressIndicator(color: Colors.blueAccent[700]),
                )
              else if (dishes.isEmpty)
                const Center(
                  child: Text(
                    "No dishes found for the selected filters.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8),
                    children: [
                      Text(
                        "Recommended Dishes",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...dishes.map((dish) => _buildDishCard(dish)).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(hint, style: const TextStyle(color: Colors.grey)),
          value: value,
          onChanged: onChanged,
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ))
              .toList(),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent[700]),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDishCard(Map<String, dynamic> dish) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          dish['name'] ?? 'Unknown Dish',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          "Flavor: ${dish['flavor_profile'] ?? 'N/A'}, Region: ${dish['region'] ?? 'N/A'}, State: ${dish['state'] ?? 'N/A'}",
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        trailing:  Icon(Icons.fastfood, color: Colors.blueAccent[700]),
      ),
    );
  }
}