import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PlaceRecommendationScreen extends StatefulWidget {
  @override
  _PlaceRecommendationScreenState createState() => _PlaceRecommendationScreenState();
}

class _PlaceRecommendationScreenState extends State<PlaceRecommendationScreen> {
  List<Map<String, dynamic>> places = [];
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetchPlaces();
  }

  Future<void> _checkLocationAndFetchPlaces() async {
    setState(() => isLoading = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _showLocationDialog();
    } else {
      _getUserLocationAndFetchPlaces();
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Location Required", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 20)),
        content: Text("Please enable location services to find nearby places."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              _checkLocationAndFetchPlaces();
            },
            child: Text("Enable Location", style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _getUserLocationAndFetchPlaces() async {
    try {
      Position position = await _getUserLocation();
      List<Map<String, dynamic>> fetchedPlaces = await _fetchNearbyPlaces(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          places = fetchedPlaces;
          errorMessage = fetchedPlaces.isEmpty ? "No places found nearby." : null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error fetching places: $e";
          isLoading = false;
        });
      }
    }
  }

  Future<Position> _getUserLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<Map<String, dynamic>>> _fetchNearbyPlaces(double lat, double lon) async {
    final String overpassQuery = """
      [out:json];
      (
        node["tourism"="attraction"](around:20000, $lat, $lon);
        node["historic"="monument"](around:20000, $lat, $lon);
        node["leisure"="park"](around:20000, $lat, $lon);
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
          "name": place["tags"]?["name"] ?? "Unknown Place",
          "lat": place["lat"] ?? place["center"]?["lat"],
          "lon": place["lon"] ?? place["center"]?["lon"],
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch places from OpenStreetMap.");
    }
  }

  void _launchGoogleMaps(double lat, double lon) {
    String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lon";
    launchUrl(Uri.parse(googleMapsUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Nearby Places to Visit",
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    SizedBox(height: 16),
                    Text("Finding nearby places...", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ],
                ),
              )
            else if (errorMessage != null)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _checkLocationAndFetchPlaces,
                      child: Text("Try Again"),
                      style: Theme.of(context).elevatedButtonTheme.style,
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: Colors.white,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Placeholder image (replace with real images later)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[300],
                                child: Icon(Icons.place, size: 40, color: Colors.grey[600]),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place['name'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "Lat: ${place['lat'].toStringAsFixed(4)}, Lon: ${place['lon'].toStringAsFixed(4)}",
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                  SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _launchGoogleMaps(place['lat'], place['lon']),
                                    icon: Icon(Icons.directions, size: 18),
                                    label: Text("Get Directions"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}