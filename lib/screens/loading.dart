import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkPhotosPermission(); // Call permission check function for photos

    _controller = AnimationController(
      duration: const Duration(seconds: 1), // Duration for both animations
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-10.0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart,
    ));

    _controller.forward();
  }

  // Function to check and request photos (READ_MEDIA_IMAGES) permission
  Future<void> _checkPhotosPermission() async {
    var status = await Permission.photos.status; // Use Permission.photos for READ_MEDIA_IMAGES
    if (!status.isGranted) {
      await Permission.photos.request(); // Request photos permission
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Center( // Keep the image centered
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'lib/images/exy.jpg',
                  width: 500,
                  height: 500,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Align( // Use Align to position the text at the bottom
            alignment: Alignment.bottomCenter, // Align text to bottom center
            child: Padding( // Add some padding from the bottom edge
              padding: const EdgeInsets.only(bottom: 320.0), // Adjust bottom padding as needed
              child: FadeTransition( // Apply FadeTransition
                opacity: _fadeAnimation,
                child: SlideTransition( // Nested SlideTransition
                  position: _slideAnimation,
                  child: const Text(
                    'Presents Exy Chat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}