import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageViewerScreen extends StatelessWidget {
  final String? imageUrl;
  final String? base64Image;
  final String? imagePath;

  const ImageViewerScreen({
    Key? key,
    this.imageUrl,
    this.base64Image,
    this.imagePath,
  }) : super(key: key);

  Future<void> _saveToGallery(BuildContext context) async {
    try {
      // Request storage permission if needed
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      if (imagePath != null) {


      } else if (base64Image != null) {
        final Uint8List bytes = base64Decode(base64Image!);

      } else if (imageUrl != null) {
        final response = await HttpClient().getUrl(Uri.parse(imageUrl!));
        final downloadedImage = await response.close();
        final bytes = await consolidateHttpClientResponseBytes(downloadedImage);
      } else {
        _showErrorSnackBar(context, 'No image source to save.');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Failed to save image: $e');
    }
  }

  void _showSaveResultSnackBar(BuildContext context, dynamic result) {
    if (result != null && result['isSuccess'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to gallery successfully!')),
      );
    } else {
      _showErrorSnackBar(context, 'Failed to save image to gallery.');
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (imagePath != null) {
      imageProvider = FileImage(File(imagePath!));
    } else if (base64Image != null) {
      imageProvider = MemoryImage(base64Decode(base64Image!));
    } else if (imageUrl != null) {
      imageProvider = NetworkImage(imageUrl!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: imageProvider != null
              ? Image(image: imageProvider)
              : const Text(
                  "Error loading image",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to spaceEvenly
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 30, 30, 30),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => _saveToGallery(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              child: const Icon(Icons.download, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}