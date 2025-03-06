import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(TFLiteTestApp());
}

class TFLiteTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TFLiteTestScreen(),
    );
  }
}

class TFLiteTestScreen extends StatefulWidget {
  @override
  _TFLiteTestScreenState createState() => _TFLiteTestScreenState();
}

class _TFLiteTestScreenState extends State<TFLiteTestScreen> {
  String _status = 'Loading model...';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      print('Attempting to load model...');
      final interpreter = await Interpreter.fromAsset('travel_recommendation.tflite');
      print('Model loaded successfully: $interpreter');
      setState(() {
        _status = 'Model loaded successfully';
      });
    } catch (e) {
      print('Failed to load model: $e');
      setState(() {
        _status = 'Failed to load model: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TFLite Test')),
      body: Center(child: Text(_status)),
    );
  }
}