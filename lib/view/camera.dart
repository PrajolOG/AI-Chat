import 'dart:io';
import 'dart:math' as math; // For mirror transform
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  int _currentCameraIndex = 0;
  bool _isFlashOn = false; // Tracks flash/torch state

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// Initialize camera with the first available camera (defaults to back camera).
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        await _setCamera(_currentCameraIndex);
      } else {
        _showSnackBar('No cameras found on device.');
      }
    } else {
      _showSnackBar('Camera permission denied');
    }
  }

  /// Set up and initialize the camera at [_currentCameraIndex].
  Future<void> _setCamera(int index) async {
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller?.dispose();
    _controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      // Reset the flash state when switching cameras.
      _isFlashOn = false;
      await _controller!.setFlashMode(FlashMode.off);
      setState(() {
        _isCameraInitialized = true;
      });
    } on CameraException catch (e) {
      debugPrint("Camera error: $e");
      _showSnackBar('Failed to initialize camera: $e');
    }
  }

  /// Switch between front and rear camera if available.
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      _showSnackBar('No additional camera to switch.');
      return;
    }
    setState(() {
      _isCameraInitialized = false;
      _isFlashOn = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });
    await _setCamera(_currentCameraIndex);
  }

  /// Toggle the flash (torch) mode if the rear camera is active.
  Future<void> _toggleFlash() async {
    // Check if we're currently using the rear camera.
    if (_cameras![_currentCameraIndex].lensDirection != CameraLensDirection.back) {
      return;
    }
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint("Error toggling flash: $e");
      _showSnackBar("Error toggling flash");
    }
  }

  /// Capture an image and return its path.
  Future<void> _takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        final XFile picture = await _controller!.takePicture();
        final Directory tempDir = await getTemporaryDirectory();
        final File file = File(picture.path);
        final File tempImage = await file.copy(
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        if (!mounted) return;
        Navigator.pop(context, tempImage.path);
      } catch (e) {
        debugPrint("Error capturing picture: $e");
        _showSnackBar('Error capturing picture: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Top bar with the Close ("X") button on the top left.
  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom bar arranged via a Stack:
  /// - Shutter button centered.
  /// - Flash button on the left.
  /// - Flip camera button on the right.
  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: double.infinity,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shutter Button in the center.
              Center(
                child: ElevatedButton(
                  onPressed: _takePicture,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.white,
                    elevation: 5,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
              ),
              // Flash button placed to the left of the shutter button.
              Transform.translate(
                offset: const Offset(-90, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      // If not on rear camera, show a disabled (greyed out) color.
                      color: (_cameras != null &&
                              _cameras!.isNotEmpty &&
                              _cameras![_currentCameraIndex].lensDirection ==
                                  CameraLensDirection.back)
                          ? Colors.white
                          : Colors.grey,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
              ),
              // Flip camera button placed to the right of the shutter button.
              Transform.translate(
                offset: const Offset(90, 0),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.cameraswitch, color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The main camera preview widget with translucent overlays.
  Widget _buildCameraPreview() {
    final bool isFrontCamera = _cameras![_currentCameraIndex].lensDirection ==
        CameraLensDirection.front;

    return Stack(
      children: [
        // Camera preview (mirrored for the front camera)
        SizedBox(
          width: double.infinity,
          child: isFrontCamera
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: CameraPreview(_controller!),
                )
              : CameraPreview(_controller!),
        ),
        // Top translucent gradient overlay.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black54, Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Bottom translucent gradient overlay.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black54],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        // Top bar with Close button.
        _buildTopBar(),
        // Bottom bar: flash button (left), shutter button (center), flip camera button (right).
        _buildBottomBar(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? _buildCameraPreview()
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }
}
