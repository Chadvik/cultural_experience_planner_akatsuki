import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'travel_models.dart';

class TravelService {
  final String baseUrl;

  TravelService({required this.baseUrl});

  Future<TravelResponse> generateTravelPlan(String userInput) async {
    final request = TravelRequest(userInput: userInput);
    final requestBody = json.encode(request.toJson());
    print('Request Body: $requestBody'); // Debug log
    final response = await http.post(
      Uri.parse('$baseUrl/travel1-plan/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: requestBody,
    ).timeout(
      Duration(seconds: 120), // 60-second timeout
      onTimeout: () {
        throw TimeoutException('The connection has timed out. Please check your internet connection.');
      },
    );
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return TravelResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to generate travel plan. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

  // Optional: Method to validate user input
  bool validateUserInput(String userInput) {
    // Basic validation - ensure input is not empty and has minimum length
    return userInput.trim().isNotEmpty && userInput.trim().length >= 10;
  }
}