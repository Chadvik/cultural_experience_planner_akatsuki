import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (result != null) {
        controller.pauseCamera();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonumentInfoScreen(qrData: result!.code!),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Monument QR')),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                result != null ? 'Scanned: ${result!.code}' : 'Scan a QR code',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonumentInfoScreen extends StatefulWidget {
  final String qrData;

  const MonumentInfoScreen({super.key, required this.qrData});

  @override
  _MonumentInfoScreenState createState() => _MonumentInfoScreenState();
}

class _MonumentInfoScreenState extends State<MonumentInfoScreen> {
  VideoPlayerController? _videoController; // Changed to nullable
  Map<String, dynamic>? monumentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMonumentData(widget.qrData);
  }

  Future<void> _fetchMonumentData(String monumentId) async {
    try {
      DocumentSnapshot doc =
      await FirebaseFirestore.instance
          .collection('monuments')
          .doc(monumentId)
          .get();

      if (doc.exists) {
        setState(() {
          monumentData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });

        final String? videoURL = monumentData?['videoURL'];
        if (videoURL != null && videoURL.isNotEmpty) {
          _videoController = VideoPlayerController.network(videoURL)
            ..initialize()
                .then((_) {
              setState(() {});
              _videoController!.play();
            })
                .catchError((error) {
              debugPrint('Error initializing video player: $error');
            });
        }
      } else {
        setState(() {
          _isLoading = false;
          monumentData = {
            'name': 'Not Found',
            'description': 'Monument not found.',
          };
        });
      }
    } catch (error) {
      debugPrint('Error fetching monument data: $error');
      setState(() {
        _isLoading = false;
        monumentData = {'name': 'Error', 'description': 'Failed to load data.'};
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose(); // Safe disposal with nullable check
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(monumentData?['name'] ?? 'Loading...')),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_videoController != null &&
                  _videoController!.value.isInitialized)
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(child: Text('No video available')),
                ),
              const SizedBox(height: 20),
              Text(
                'Description: ${monumentData?['description'] ?? 'No details available.'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (_videoController != null &&
                  _videoController!.value.isInitialized)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: Text(
                    _videoController!.value.isPlaying
                        ? 'Pause'
                        : 'Play',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
