// lib/models/travel_models.dart
class TravelRequest {
  final String userInput;

  TravelRequest({required this.userInput});

  Map<String, dynamic> toJson() => {'user_input': userInput};
}

class TravelResponse {
  final String extractedInfo;
  final String itinerary;
  final String etiquetteTips;

  TravelResponse({
    required this.extractedInfo,
    required this.itinerary,
    required this.etiquetteTips,
  });

  factory TravelResponse.fromJson(Map<String, dynamic> json) {
    return TravelResponse(
      extractedInfo: json['extracted_info'] ?? '',
      itinerary: json['itinerary'] ?? '',
      etiquetteTips: json['etiquette_tips'] ?? '',
    );
  }

  Map<String, String> parseExtractedInfo() {
    Map<String, String> parsedInfo = {};
    List<String> parts = extractedInfo.split(';');
    for (var part in parts) {
      List<String> keyValue = part.split(': ');
      if (keyValue.length == 2) {
        parsedInfo[keyValue[0].trim()] = keyValue[1].trim();
      }
    }
    return parsedInfo;
  }

  Map<String, List<String>> parseItineraryDayWise() {
    Map<String, List<String>> dayWise = {};
    List<String> lines = itinerary.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    print('Raw itinerary input: "$itinerary"'); // Debug raw input
    print('Split lines: $lines'); // Debug split lines

    if (lines.isEmpty) {
      return {'Day 1': ['No itinerary provided']};
    }

    // Regex to match "Day X" (case-insensitive, flexible format)
    RegExp dayHeader = RegExp(r'^(day\s*\d+)', caseSensitive: false);
    String? currentDay;

    for (var line in lines) {
      var match = dayHeader.firstMatch(line);
      if (match != null) {
        // Found a "Day X" heading
        currentDay = match.group(0)!.trim(); // e.g., "Day 1"
        dayWise[currentDay] = [];
      } else if (currentDay != null) {
        // Add content to the current day
        dayWise[currentDay]!.add(line);
      } else {
        // No day header yet, start with "Day 1"
        currentDay = 'Day 1';
        dayWise[currentDay] = [line];
      }
    }

    print('Parsed day-wise itinerary: $dayWise'); // Debug parsed output
    return dayWise.isEmpty ? {'Day 1': ['No itinerary provided']} : dayWise;
  }
}

class TravelPackage {
  final String userId;
  final String destination;
  final int duration;
  final Map<String, List<String>> itinerary;
  final List<String> etiquetteTips;
  final String createdAt;
  final String packageId;

  TravelPackage({
    required this.userId,
    required this.destination,
    required this.duration,
    required this.itinerary,
    required this.etiquetteTips,
    required this.createdAt,
    required this.packageId,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'destination': destination,
    'duration': duration,
    'itinerary': itinerary,
    'etiquetteTips': etiquetteTips,
    'createdAt': createdAt,
    'packageId': packageId,
  };

  factory TravelPackage.fromJson(Map<String, dynamic> json) {
    print('Raw JSON from Firebase: $json');

    final rawDuration = json['duration'];
    final int parsedDuration = rawDuration is int
        ? rawDuration
        : rawDuration is String
        ? int.tryParse(rawDuration) ?? 1
        : 1;

    return TravelPackage(
      userId: json['userId']?.toString() ?? 'unknown_user',
      destination: json['destination']?.toString() ?? 'Unknown',
      duration: parsedDuration,
      itinerary: json['itinerary'] != null
          ? (json['itinerary'] as Map<String, dynamic>).map((key, value) => MapEntry(key, List<String>.from(value)))
          : {'Day 1': ['No itinerary provided']},
      etiquetteTips: json['etiquetteTips'] != null ? List<String>.from(json['etiquetteTips']) : [],
      createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      packageId: json['packageId']?.toString() ?? 'unknown_package',
    );
  }
}

class Booking {
  final String userId;
  final TravelPackage package;
  final String bookedAt;

  Booking({
    required this.userId,
    required this.package,
    required this.bookedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'package': package.toJson(),
    'bookedAt': bookedAt,
  };

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      userId: json['userId']?.toString() ?? 'unknown_user',
      package: TravelPackage.fromJson(json['package'] as Map<String, dynamic>),
      bookedAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }
}