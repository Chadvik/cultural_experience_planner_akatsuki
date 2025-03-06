// lib/screens/package_detail_screen.dart
import 'package:flutter/material.dart';
import 'travel_models.dart';

class PackageDetailScreen extends StatelessWidget {
  final TravelPackage package;

  PackageDetailScreen({required this.package});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${package.destination} Package'), backgroundColor: Colors.deepPurple),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Destination: ${package.destination}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Duration: ${package.duration} days', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text('Itinerary:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...package.itinerary.entries.map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                  ...entry.value.map((item) => Text('  - $item')),
                ],
              ),
            )),
            SizedBox(height: 16),
            Text('Etiquette Tips:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...package.etiquetteTips.map((tip) => Text('  - $tip')),
          ],
        ),
      ),
    );
  }
}