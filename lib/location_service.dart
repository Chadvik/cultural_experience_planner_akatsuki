import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  /// 📌 Get User Location & City Name
  static Future<String?> getCurrentCity() async {
    return _getCityFromCoordinates(0.0, 0.0); // Lat/Lon values won't matter as we're returning static data.
  }

  /// 📌 Convert Lat/Lng to City Name (Hardcoded)
  static Future<String?> _getCityFromCoordinates(double lat, double lon) async {
    return "Indore"; // 🔹 Always returns "Indore"
  }
}
