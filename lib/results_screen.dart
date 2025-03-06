import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  final List<String> recommendations;

  ResultsScreen({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Recommendations')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recommended Destinations:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            if (recommendations.isNotEmpty)
              ...recommendations.map((city) => Text('• $city', style: TextStyle(fontSize: 16))).toList()
            else
              Text('No recommendations available', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}