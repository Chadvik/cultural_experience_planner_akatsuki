import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static Future<Position> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check and request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<List<Map<String, dynamic>>> fetchNearbyRestaurants(double latitude, double longitude) async {
    try {
      // Use Overpass API to fetch nearby restaurants
      final String overpassQuery = '''
      [out:json];
      node["amenity"="restaurant"](around:1000, $latitude, $longitude);
      out body;
      ''';
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> restaurants = [];
        for (var element in data['elements']) {
          if (element['tags'] != null && element['tags']['name'] != null) {
            restaurants.add({
              'name': element['tags']['name'],
              'lat': element['lat'],
              'lon': element['lon'],
            });
          }
        }
        return restaurants.take(5).toList(); // Limit to 5 nearby restaurants
      } else {
        throw Exception('Failed to fetch nearby restaurants: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching nearby restaurants: $e');
    }
  }
}