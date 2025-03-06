import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'firebase_options.dart';
import 'package:flutter_gemini/flutter_gemini.dart'; // Gemini API



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,

  );
  Gemini.init(apiKey: "AIzaSyAzaIbRGFLiEf285e77M0_R5qH14n5ybr0");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel',
      theme: getAppTheme(),
      home: LoginPage(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginPage(),
      },
    );
  }
}

ThemeData getAppTheme() {
  return ThemeData(
    // scaffoldBackgroundColor: Colors.amber[50],
    primaryColor: Colors.blueAccent,
    colorScheme: ColorScheme.light(
      primary: Colors.blueAccent!,
      secondary: Colors.black!,
      surface: Colors.white,
      // background: Colors.amber[50]!,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(color: Colors.black),
      labelLarge: TextStyle(fontSize: 18, color: Colors.white), // Button text
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white, // Text and icon color
        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.blueAccent!, width: 2),
      ),
      prefixIconColor: Colors.blueAccent,
    ),
  );
}