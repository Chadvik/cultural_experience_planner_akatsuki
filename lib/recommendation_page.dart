import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added for hasCompletedRecommendations
import 'home_page.dart';

class RecommendationScreen extends StatefulWidget {
  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  Interpreter? _interpreter;
  Map<String, dynamic>? _encoders;
  Map<String, dynamic>? _cityMapping;
  List<String> recommendations = [];
  String travelerType = '';

  String? experience, activity, climate, travelStyle, destinationType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModelAndAssets();
  }

  Future<void> _loadModelAndAssets() async {
    setState(() => _isLoading = true);
    try {
      _interpreter = await Interpreter.fromAsset('assets/recommendation_model.tflite');
      String encoderData = await rootBundle.loadString('assets/encoders.json');
      String cityData = await rootBundle.loadString('assets/city_mapping.json');
      _encoders = json.decode(encoderData) as Map<String, dynamic>;
      _cityMapping = json.decode(cityData) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading model or assets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading recommendations: $e'),
          backgroundColor: Colors.blueAccent[100],
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getRecommendations() async {
    if (_interpreter == null || _encoders == null || _cityMapping == null ||
        experience == null || activity == null || climate == null ||
        travelStyle == null || destinationType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select all preferences and wait for assets to load'),
          backgroundColor: Colors.blueAccent[100],
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      double expEncoded = _encoders!['experiences'].indexOf(experience!).toDouble();
      double actEncoded = _encoders!['activity'].indexOf(activity!).toDouble();
      double climateEncoded = _encoders!['climate'].indexOf(climate!).toDouble();
      double travelStyleEncoded = _encoders!['travel_style'].indexOf(travelStyle!).toDouble();
      double destTypeEncoded = _encoders!['destination_type'].indexOf(destinationType!).toDouble();
      double travelerTypeEncoded = 0; // Placeholder

      List<double> input = [
        expEncoded,
        actEncoded,
        climateEncoded,
        travelStyleEncoded,
        destTypeEncoded,
        travelerTypeEncoded
      ];

      var inputTensor = [input];
      var outputTensor = List.filled(1, List.filled(_cityMapping!.length, 0.0));

      _interpreter!.run(inputTensor, outputTensor);

      List<double> probabilities = outputTensor[0];
      List<int> topIndices = [];
      for (int i = 0; i < probabilities.length; i++) {
        topIndices.add(i);
      }
      topIndices.sort((a, b) => probabilities[b].compareTo(probabilities[a]));
      topIndices = topIndices.take(3).toList();

      List<String> cities = [];
      for (int index in topIndices) {
        String? cityList = _cityMapping![index.toString()];
        if (cityList != null) {
          cities.addAll(cityList.split(', ').where((city) => city.isNotEmpty));
        }
      }
      cities = cities.toSet().toList().take(3).toList();

      int maxIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));
      travelerType = _encoders!['traveler_type'][maxIndex % _encoders!['traveler_type'].length] as String;

      // Set hasCompletedRecommendations to true after generating recommendations
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCompletedRecommendations', true);

      setState(() {
        recommendations = cities;
        this.travelerType = travelerType;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting recommendations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating recommendations: $e'),
          backgroundColor: Colors.blueAccent[100],
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Travel Recommendation',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            tooltip: 'Go to Home',
          ),
        ],
      ),
      backgroundColor: Colors.blue[50],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 4.0,
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What kind of experiences excite you?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: experience,
                items: (_encoders?['experiences'] as List<dynamic>?)?.map<DropdownMenuItem<String>>((dynamic value) {
                  return DropdownMenuItem<String>(
                    value: value as String,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }).toList() ?? [],
                onChanged: (value) => setState(() => experience = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: Text('Select experience', style: GoogleFonts.poppins(color: Colors.grey[600])),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Which activities do you enjoy?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: activity,
                items: (_encoders?['activity'] as List<dynamic>?)?.map<DropdownMenuItem<String>>((dynamic value) {
                  return DropdownMenuItem<String>(
                    value: value as String,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }).toList() ?? [],
                onChanged: (value) => setState(() => activity = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: Text('Select activity', style: GoogleFonts.poppins(color: Colors.grey[600])),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Preferred climate?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: climate,
                items: (_encoders?['climate'] as List<dynamic>?)?.map<DropdownMenuItem<String>>((dynamic value) {
                  return DropdownMenuItem<String>(
                    value: value as String,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }).toList() ?? [],
                onChanged: (value) => setState(() => climate = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: Text('Select climate', style: GoogleFonts.poppins(color: Colors.grey[600])),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Travel style?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: travelStyle,
                items: (_encoders?['travel_style'] as List<dynamic>?)?.map<DropdownMenuItem<String>>((dynamic value) {
                  return DropdownMenuItem<String>(
                    value: value as String,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }).toList() ?? [],
                onChanged: (value) => setState(() => travelStyle = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: Text('Select travel style', style: GoogleFonts.poppins(color: Colors.grey[600])),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Text(
                'Destination type?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent[700],
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: destinationType,
                items: (_encoders?['destination_type'] as List<dynamic>?)?.map<DropdownMenuItem<String>>((dynamic value) {
                  return DropdownMenuItem<String>(
                    value: value as String,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(fontSize: 16),
                    ),
                  );
                }).toList() ?? [],
                onChanged: (value) => setState(() => destinationType = value),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                hint: Text('Select destination type', style: GoogleFonts.poppins(color: Colors.grey[600])),
                dropdownColor: Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: experience != null &&
                    activity != null &&
                    climate != null &&
                    travelStyle != null &&
                    destinationType != null
                    ? _getRecommendations
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Get Recommendations',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              if (recommendations.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You are a $travelerType!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Recommended Cities:',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent[700],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...recommendations.map((city) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '- $city',
                                style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    'Click to Continue to Home Page',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

    );
  }
}