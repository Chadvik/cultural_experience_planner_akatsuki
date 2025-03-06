import 'package:flutter/material.dart';
import 'package:o3d/o3d.dart';
import 'add_to_itinerary_page.dart';

class ArHomePage extends StatefulWidget {
  const ArHomePage({super.key, required this.title});

  final String title;

  @override
  State<ArHomePage> createState() => _ArHomePageState();
}

class _ArHomePageState extends State<ArHomePage> {
  O3DController controller = O3DController();
  bool isAR = true;
  String selectedModel = 'assets/source/uploads_files_3451154_interior.glb';
  Key o3dKey = UniqueKey(); // Key to force O3D widget rebuild

  // Mock model options with metadata
  final Map<String, Map<String, String>> models = {
    'assets/source/uploads_files_3451154_interior.glb': {
      'name': 'Hotel Room',
      'tip': 'Bedhseets are of cotton and Room service is also provided.',
      'phrase': 'Room service, Breakfast ',
      'guide': 'Hiroshi',
    },
    'assets/source/monument.glb': {
      'name': 'Monument',
      'tip':
      'Colosseum, giant amphitheater built in Rome under the Flavian emperors. Unlike earlier amphitheaters, the Colosseum is a freestanding structure of stone and concrete that uses a complex system of vaults.',
      'phrase': 'Namaste = Greetings',
      'guide': 'Aisha',
    },
    'assets/source/hechosetobehappy.fbx.glb': {
      'name': 'Local Guide',
      'tip': 'Bow slightly to greet.',
      'phrase': 'Arigatou = Thank you',
      'guide': 'Yuki',
    },
  };

  void changeModel(String newModel) {
    setState(() {
      selectedModel = newModel;
      o3dKey = UniqueKey(); // Refresh O3D widget by changing its key
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(
          204,
          0,
          128,
          128,
        ), // Teal with 80% opacity (204/255)
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white),
            onPressed: () => setState(() => isAR = !isAR),
            tooltip: 'Toggle AR',
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right, color: Colors.white),
            onPressed: () => controller.cameraOrbit(20, 20, 5),
            tooltip: 'Rotate View',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background when AR is off
          if (!isAR)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.tealAccent, Colors.blueGrey],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          // AR/3D Model Viewer with Key
          O3D(
            key: o3dKey, // Forces rebuild when model changes
            controller: controller,
            src: selectedModel,
            ar: true,
            autoPlay: true,
            autoRotate: selectedModel.contains('guide') ? false : true,
            cameraControls: true,
            cameraTarget: CameraTarget(0, 1, 0),
            cameraOrbit: CameraOrbit(0, 90, 2),
          ),
          // HUD Overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color.fromARGB(
                  178,
                  0,
                  0,
                  0,
                ), // Black with 70% opacity (178/255)
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exploring: ${models[selectedModel]!['name']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cultural Tip: ${models[selectedModel]!['tip']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Phrase: ${models[selectedModel]!['phrase']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Local Guide: ${models[selectedModel]!['guide']}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          // Model Selection
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: DropdownButton<String>(
              value: selectedModel,
              onChanged: (String? newValue) {
                if (newValue != null) changeModel(newValue);
              },
              items:
              models.keys.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    models[value]!['name']!,
                    style: const TextStyle(color: Colors.teal),
                  ),
                );
              }).toList(),
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Adjust this value to move up more or less
        child: FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Like it ? Add to your itinerary'),
                content: Text(
                  'Add ${models[selectedModel]!['name']} to your trip?\n Your Guide : ${models[selectedModel]!['guide']}',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddToItineraryPage(
                            modelName: models[selectedModel]!['name']!,
                            guide: models[selectedModel]!['guide']!,
                            packageId: 'package1',
                          ),
                        ),
                      );
                    },
                    child: const Text('Yes'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No'),
                  ),
                ],
              ),
            );
          },
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add_location),
        ),
      ),
    );
  }
}