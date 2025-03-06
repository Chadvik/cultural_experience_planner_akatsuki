// lib/screens/travel_planning_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'travel_service.dart';
import 'travel_models.dart';
import 'personalized_packages_screen.dart';

class TravelPlanningScreen extends StatefulWidget {
  @override
  _TravelPlanningScreenState createState() => _TravelPlanningScreenState();
}

class _TravelPlanningScreenState extends State<TravelPlanningScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TravelService _travelService = TravelService(baseUrl: 'http://192.168.0.123:8001');
  TravelResponse? _travelResponse;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _generateTravelPlan() async {
    if (!_travelService.validateUserInput(_inputController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter more detailed travel preferences'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _travelService.generateTravelPlan(_inputController.text);
      setState(() {
        _travelResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }
  Future<void> _saveTravelPackage() async {
    if (_travelResponse == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorDialog('Please log in to save your travel package.');
      return;
    }

    final extractedInfo = _travelResponse!.parseExtractedInfo();
    final itinerary = _travelResponse!.parseItineraryDayWise(); // This triggers the print statements
    final etiquetteTips = _travelResponse!.etiquetteTips.split('\n').where((tip) => tip.trim().isNotEmpty).toList();

    String durationStr = extractedInfo['Duration'] ?? '1';
    int duration = int.tryParse(RegExp(r'\d+').firstMatch(durationStr)?.group(0) ?? '1') ?? 1;

    final travelPackage = TravelPackage(
      userId: user.uid,
      destination: extractedInfo['Destination City'] ?? 'Unknown',
      duration: duration,
      itinerary: itinerary,
      etiquetteTips: etiquetteTips,
      createdAt: DateTime.now().toIso8601String(),
      packageId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('personalized_packages')
          .doc(travelPackage.packageId)
          .set(travelPackage.toJson());
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalizedPackagesScreen(userId: user.uid)),
      );
    } catch (e) {
      _showErrorDialog('Failed to save package: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [TextButton(child: Text('Okay'), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Travel Planner'), centerTitle: true, backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: 'Enter your travel preferences',
                hintText: 'e.g., I love art and history. I am visiting Hyderabad for 2 days',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.travel_explore),
                filled: true,
                fillColor: Colors.blue[50],
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _generateTravelPlan,
              icon: Icon(Icons.travel_explore),
              label: Text('Generate Travel Plan'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                foregroundColor: Colors.white, // Text and icon color
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent))),
            if (_travelResponse != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionWithIcon('Extracted Information', Icons.info_outline),
                          _buildInfoRow('Destination City', _cleanText(_travelResponse!.parseExtractedInfo()['Destination City'])),
                          _buildInfoRow('Country', _cleanText(_travelResponse!.parseExtractedInfo()['Country'])),
                          _buildInfoRow('Duration', _cleanText(_travelResponse!.parseExtractedInfo()['Duration'])),
                          SizedBox(height: 16),
                          _buildSectionWithIcon('Itinerary', Icons.schedule),
                          _buildItinerarySection(_cleanText(_travelResponse!.itinerary)),
                          SizedBox(height: 16),
                          _buildSectionWithIcon('Etiquette Tips', Icons.info),
                          _buildEtiquetteSection(_cleanText(_travelResponse!.etiquetteTips)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveTravelPackage,
                icon: Icon(Icons.card_travel),
                label: Text('Get Your Travel Ready'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Colors.white, // Text and icon color
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _cleanText(String? text) => text?.replaceAll(RegExp(r'[*\â\€\ã\ƒ\¢]'), '').trim() ?? 'Not Available';

  Widget _buildSectionWithIcon(String title, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent[700])),
      ],
    ),
  );

  Widget _buildInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      children: [
        Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent[600])),
        Expanded(child: Text(value, style: TextStyle(color: Colors.black87))),
      ],
    ),
  );

  Widget _buildItinerarySection(String itinerary) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: itinerary.split('\n').map((line) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8),
          Expanded(child: Text(line.trim(), style: TextStyle(color: Colors.black87))),
        ],
      ),
    )).toList(),
  );

  Widget _buildEtiquetteSection(String etiquetteTips) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: etiquetteTips.split('\n').map((line) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 8),
          Expanded(child: Text(line.trim(), style: TextStyle(color: Colors.black87))),
        ],
      ),
    )).toList(),
  );

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}