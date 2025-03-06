import 'package:flutter/material.dart';
import 'travel_planning_screen.dart';

class TravelPlannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Optional: Customize app-wide text styling
        textTheme: TextTheme(
          bodyMedium: TextStyle(fontSize: 16),
          bodyLarge: TextStyle(fontSize: 18),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      home: TravelPlanningScreen(),
      // Optional: Remove debug banner
      debugShowCheckedModeBanner: false,
    );
  }
}