import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class MonumentClassifier extends StatefulWidget {
  const MonumentClassifier({super.key});

  @override
  _MonumentClassifierState createState() => _MonumentClassifierState();
}

class _MonumentClassifierState extends State<MonumentClassifier> {
  Interpreter? _interpreter;
  File? _selectedImage;
  String _prediction = "No Prediction Yet";
  bool _isLoading = false;
  List<int>? _inputShape;
  List<int>? _outputShape;

  // Manual mapping of known indices to your 5 classes (update these after testing)
  final Map<int, String> landmarkMapping = {
    70154: "Taj Mahal, Agra",
    45332: "Mahakal Temple, Ujjain",
    21727: "Red Fort, Delhi",
    42219: "India Gate, Delhi",
    97675: "Hawa Mahal, Jaipur",
    2831: "Golden Temple, Amritsar",
    92838: "Qutub Minar, Delhi",
    70480: "Meenakshi Temple, Madhurai",
    91766: "Konark Sun Temple, Odisha",
  };

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/1.tflite');
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      print(
        "✅ Model Loaded: Input Shape: $_inputShape, Output Shape: $_outputShape",
      );

      if (_outputShape![1] != 5) {
        print(
          "⚠️ Warning: Using Google Landmarks Classifier Asia V1 with ${_outputShape![1]} outputs. Using manual mapping.",
        );
      }
    } catch (e) {
      print("❌ Error loading model: $e");
      setState(() {
        _prediction = "Error: Failed to load model ($e)";
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _prediction = "Processing...";
      });
      await _classifyImage();
    }
  }

  List<List<List<List<int>>>> _preprocessImage(File imageFile) {
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());
    if (image == null) throw Exception("Failed to decode image");

    const int targetSize = 321;

    img.Image resizedImage = img.copyResize(
      image,
      width: targetSize,
      height: targetSize,
    );

    List<List<List<List<int>>>> inputTensor = List.generate(
      1,
      (_) => List.generate(
        targetSize,
        (y) => List.generate(targetSize, (x) => List.generate(3, (_) => 0)),
      ),
    );

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);
        inputTensor[0][y][x][0] = pixel.r.toInt();
        inputTensor[0][y][x][1] = pixel.g.toInt();
        inputTensor[0][y][x][2] = pixel.b.toInt();
      }
    }

    print("📷 Preprocessed image sample: ${inputTensor[0][0][0]}");
    return inputTensor;
  }

  Future<void> _classifyImage() async {
    if (_interpreter == null || _selectedImage == null) {
      setState(() {
        _prediction = "Error: Model not loaded or no image selected";
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<List<List<List<int>>>> inputTensor = _preprocessImage(
        _selectedImage!,
      );
      List<List<double>> outputTensor = [List.filled(_outputShape![1], 0.0)];

      _interpreter!.run(inputTensor, outputTensor);

      final scores = outputTensor[0];
      print("📈 Total output length: ${scores.length}");

      List<MapEntry<int, double>> indexedScores =
          scores.asMap().entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final topScore = indexedScores[0].value;
      final topIndex = indexedScores[0].key;

      print("📈 Top 5 scores with indices: ${indexedScores.take(5).toList()}");

      // Use manual mapping
      final predictedLandmark = landmarkMapping[topIndex];

      print(
        "🔍 Raw predicted index: $topIndex, Mapped landmark: $predictedLandmark, Max score: $topScore",
      );

      setState(() {
        if (predictedLandmark != null && topScore > 0.1) {
          _prediction =
              "$predictedLandmark (Confidence: ${(topScore * 100).toStringAsFixed(2)}%)";
        } else {
          _prediction = "Unknown (Not in mapping or low confidence)";
        }
      });
    } catch (e) {
      print("❌ Error running inference: $e");
      setState(() {
        _prediction = "Error: Failed to classify image ($e)";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monument Classifier")),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _selectedImage == null
                    ? const Text("No image selected")
                    : Image.file(_selectedImage!, height: 300),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _pickImage,
                  child: const Text("Select Image"),
                ),
                const SizedBox(height: 20),
                Text(
                  "Prediction: $_prediction",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
