import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class RestaurantRecommendationScreen extends StatefulWidget {
  const RestaurantRecommendationScreen({super.key});

  @override
  _RestaurantRecommendationScreenState createState() => _RestaurantRecommendationScreenState();
}

class _RestaurantRecommendationScreenState extends State<RestaurantRecommendationScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> restaurants = [];
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _getUserLocationAndFetchRestaurants();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocationAndFetchRestaurants() async {
    setState(() {
      errorMessage = null;
    });
    try {
      Position position = await _getUserLocation();
      List<Map<String, dynamic>> fetchedRestaurants = await _fetchNearbyRestaurants(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          restaurants = fetchedRestaurants;
          errorMessage = fetchedRestaurants.isEmpty ? "No restaurants found within 20km." : null;
        });
        _animationController.forward(from: 0.0); // Start animation
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error: $e";
        });
      }
    }
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled. Please enable them.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<Map<String, dynamic>>> _fetchNearbyRestaurants(double lat, double lon) async {
    final String overpassQuery = """
      [out:json];
      (
        node["amenity"="restaurant"](around:20000, $lat, $lon);
        way["amenity"="restaurant"](around:20000, $lat, $lon);
        relation["amenity"="restaurant"](around:20000, $lat, $lon);
      );
      out center;
    """;

    final String url = "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      List elements = data['elements'];
      return elements.map((place) {
        return {
          "name": place["tags"]?["name"] ?? "Unnamed Restaurant",
          "lat": place["lat"] ?? place["center"]?["lat"],
          "lon": place["lon"] ?? place["center"]?["lon"],
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch restaurants from OpenStreetMap.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent[700]!, Colors.blue[50]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Nearby Restaurants",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(2, 2))],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _getUserLocationAndFetchRestaurants,
                      tooltip: "Refresh",
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: restaurants.isEmpty && errorMessage == null
                      ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        if (errorMessage != null)
                          Card(
                            color: Colors.redAccent.withOpacity(0.9),
                            margin: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        Expanded(
                          child: restaurants.isNotEmpty
                              ? ListView.builder(
                            itemCount: restaurants.length,
                            itemBuilder: (context, index) {
                              final restaurant = restaurants[index];
                              return AnimatedRestaurantCard(restaurant: restaurant);
                            },
                          )
                              : const SizedBox.shrink(),
                        ),
                      ],
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
}

class AnimatedRestaurantCard extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const AnimatedRestaurantCard({required this.restaurant});

  @override
  _AnimatedRestaurantCardState createState() => _AnimatedRestaurantCardState();
}

class _AnimatedRestaurantCardState extends State<AnimatedRestaurantCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    return GestureDetector(
      onTap: () {
        String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${restaurant['lat']},${restaurant['lon']}";
        launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(vertical: 10),
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          child: Card(
            elevation: _isHovered ? 12 : 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white.withOpacity(0.9),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.blueAccent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  // Restaurant Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Lat: ${restaurant['lat'].toStringAsFixed(4)}, Lon: ${restaurant['lon'].toStringAsFixed(4)}",
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  // Navigate Button
                  IconButton(
                    icon: const Icon(Icons.directions, color: Colors.blueAccent, size: 28),
                    onPressed: () {
                      String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=${restaurant['lat']},${restaurant['lon']}";
                      launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
                    },
                    tooltip: "Open in Google Maps",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




// // for fixed location- khajrana
//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';
//
//
// class RestaurantRecommendationScreen extends StatefulWidget {
//   @override
//   _RestaurantRecommendationScreenState createState() => _RestaurantRecommendationScreenState();
// }
//
// class _RestaurantRecommendationScreenState extends State<RestaurantRecommendationScreen> {
//   List<Map<String, dynamic>> restaurants = [];
//   String? errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchNearbyRestaurants(22.70238, 75.91785); // Using fixed coordinates
//   }
//
//   Future<List<Map<String, dynamic>>> _fetchNearbyRestaurants(double lat, double lon) async {
//     final String overpassQuery = """
//       [out:json];
//       (
//         node["amenity"="restaurant"](around:5000, $lat, $lon);
//         way["amenity"="restaurant"](around:5000, $lat, $lon);
//         relation["amenity"="restaurant"](around:5000, $lat, $lon);
//       );
//       out center;
//     """;
//
//     final String url = "https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}";
//
//     try {
//       final response = await http.get(Uri.parse(url));
//
//       if (response.statusCode == 200) {
//         final Map<String, dynamic> data = json.decode(response.body);
//         List elements = data['elements'];
//
//         return elements.map((place) {
//           return {
//             "name": place["tags"]?["name"] ?? "Unknown",
//             "lat": place["lat"] ?? place["center"]?["lat"],
//             "lon": place["lon"] ?? place["center"]?["lon"],
//           };
//         }).toList();
//       } else {
//         throw Exception("Failed to fetch restaurants from OpenStreetMap.");
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = "Error fetching restaurants: $e";
//       });
//       return [];
//     }
//   }
//
//   @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(title: Text("Nearby Restaurants")),
//     body: Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           if (errorMessage != null)
//             Text(
//               errorMessage!,
//               style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//
//           Expanded(
//             child: FutureBuilder<List<Map<String, dynamic>>>(
//               future: _fetchNearbyRestaurants(22.70238, 75.91785),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(child: CircularProgressIndicator());
//                 } else if (snapshot.hasError) {
//                   return Center(child: Text("Error: ${snapshot.error}"));
//                 } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
//                   return ListView(
//                     children: snapshot.data!.map((restaurant) {
//                       return ListTile(
//                         title: Text(restaurant['name']),
//                         subtitle: Text("Coordinates: ${restaurant['lat']}, ${restaurant['lon']}"),
//                         onTap: () {
//                           String googleMapsUrl =
//                               "https://www.google.com/maps/dir/?api=1&destination=${restaurant['lat']},${restaurant['lon']}";
//                           launchUrl(Uri.parse(googleMapsUrl));
//                         },
//                       );
//                     }).toList(),
//                   );
//                 } else {
//                   return Center(child: Text("No restaurants found nearby."));
//                 }
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }