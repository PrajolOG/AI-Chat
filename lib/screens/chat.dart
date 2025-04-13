// chat.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:photo_manager/photo_manager.dart'; // Import photo_manager
import 'package:flutter_highlight/themes/atom-one-dark-reasonable.dart'; // Import the theme

import 'image_viewer_screen.dart';
import '../view/format.dart'; // Import the centralized formatting widgets


/// Basic chat message model.
class ChatMessage {
  String text;
  final bool isUser;
  final bool isSystemMessage;
  bool isInitialSystemMessage;
  String? imageUrl;
  String? base64Image;
  String? imagePath;
  bool isFullWidth; // Add this line
  AssetEntity? asset; // Add AssetEntity

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isSystemMessage = false,
    this.isInitialSystemMessage = false,
    this.imageUrl,
    this.base64Image,
    this.imagePath,
    this.isFullWidth = false, // Initialize to false by default
    this.asset, // Initialize AssetEntity
  });

  // For an image with a remote URL
  ChatMessage.image({
    required this.isUser,
    this.imageUrl,
    this.base64Image,
    this.isSystemMessage = false,
    this.isInitialSystemMessage = false,
    this.text = '',
    this.imagePath,
    this.isFullWidth = false,
    this.asset, // Initialize AssetEntity
  });

  // For an image stored locally on device
  ChatMessage.imagePath({
    required this.isUser,
    required this.imagePath,
    this.isSystemMessage = false,
    this.isInitialSystemMessage = false,
    this.text = '',
    this.imageUrl,
    this.base64Image,
    this.isFullWidth = false,
    this.asset, // Initialize AssetEntity
  });

  // For an image in base64
  ChatMessage.base64Image({
    required this.base64Image,
    required this.isUser,
    this.isSystemMessage = false,
    this.isInitialSystemMessage = false,
    this.text = '',
    this.imageUrl,
    this.imagePath,
    this.isFullWidth = false,
    this.asset, // Initialize AssetEntity
  });

  // For AssetEntity image
  ChatMessage.asset({
    required this.isUser,
    required this.asset,
    this.isSystemMessage = false,
    this.isInitialSystemMessage = false,
    this.text = '',
    this.imageUrl,
    this.base64Image,
    this.imagePath,
    this.isFullWidth = false,
  });
}

 // CopyableBubble is defined below as it's specific to chat bubble interaction

 /// A widget that wraps its child with a long-press "Copy" context menu.
 class CopyableBubble extends StatefulWidget {
   final String text;
   final Widget child;

   const CopyableBubble({Key? key, required this.text, required this.child})
       : super(key: key);

   @override
   _CopyableBubbleState createState() => _CopyableBubbleState();
 }

 class _CopyableBubbleState extends State<CopyableBubble> {
   Offset? _tapPosition;

   void _storePosition(TapDownDetails details) {
     _tapPosition = details.globalPosition;
   }

   Future<void> _showContextMenu() async {
     final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
     // Define dark theme colors for the menu
     const menuBackgroundColor = Color.fromARGB(255, 30, 30, 30); // Match user bubble color
     const menuTextColor = Colors.white;
     final menuShape = RoundedRectangleBorder(
       borderRadius: BorderRadius.circular(8.0), // Add some rounding
     );

     final selected = await showMenu<String>( // Specify type argument
       context: context,
       color: menuBackgroundColor, // Set background color
       shape: menuShape, // Set shape
       position: RelativeRect.fromRect(
         Rect.fromLTWH(_tapPosition?.dx ?? 0, _tapPosition?.dy ?? 0, 30, 30), // Give it a small size
         Offset.zero & overlay.size,
       ),
       items: [ // Must be a List<PopupMenuEntry<String>>
         const PopupMenuItem<String>(
           value: 'copy',
           child: Text(
             'Copy',
             style: TextStyle(color: menuTextColor), // Set text color
           ),
         )
       ],
       elevation: 8.0, // Optional: Adjust elevation
     );
     if (selected == 'copy') {
       await Clipboard.setData(ClipboardData(text: widget.text));
     }
   }

   @override
   Widget build(BuildContext context) {
     return GestureDetector(
       onTapDown: _storePosition,
       onLongPress: _showContextMenu,
       child: widget.child,
     );
   }
 }

class BreathingDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const BreathingDot({
    Key? key,
    this.color = Colors.white,
    this.size = 12.0,
    this.duration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  _BreathingDotState createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Create an animation controller that repeatedly "breathes" (pulses) in reverse.
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    // Tween animates the dot's scale between 0.8 and 1.2 for a smooth effect.
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// The main chat widget, listing all messages and optionally showing a "Typing..." indicator.
class ChatWidget extends StatelessWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final bool isTyping;

  const ChatWidget({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.isTyping = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the only message is the initial system message
    if (messages.length == 1 && messages.first.isInitialSystemMessage) {
      final initialMessage = messages.first;
      // Parse new structure: Welcome, Tagline, Header, Suggestions
      List<String> suggestions = [];
      String welcomeText = "";
      String taglineText = "";
      String headerText = "";
      final lines = initialMessage.text.split('\n');

      if (lines.isNotEmpty) welcomeText = lines[0];
      if (lines.length > 1 && lines[1].startsWith("[TAGLINE]")) {
        taglineText = lines[1].substring("[TAGLINE]".length);
      }
      if (lines.length > 2 && lines[2].startsWith("[HEADER]")) {
        headerText = lines[2].substring("[HEADER]".length);
      }
      for (int i = 3; i < lines.length; i++) { // Suggestions start from line 3 now
        if (lines[i].trim().startsWith('- ')) {
          suggestions.add(lines[i].trim().substring(2).trim());
        }
      }

      // Build the centered initial message widget
      // Enhanced design, wrapped in SingleChildScrollView for keyboard responsiveness
      return Center(
        child: SingleChildScrollView( // Added SingleChildScrollView
          child: Container(
            margin: const EdgeInsets.all(20.0),
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 18, 18, 18),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Welcome Text
                CopyableBubble(
                  text: welcomeText,
                  child: FormattedText(
                    text: welcomeText,
                    textStyle: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline Text
                if (taglineText.isNotEmpty)
                  CopyableBubble(
                    text: taglineText,
                    child: FormattedText(
                      text: taglineText,
                      textStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 20),

                // Header Text
                if (headerText.isNotEmpty)
                  CopyableBubble(
                    text: headerText,
                    child: FormattedText(
                      text: headerText,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),

                // Suggestion Boxes
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  alignment: WrapAlignment.center,
                  children: suggestions
                      .map(
                        (suggestion) => _buildSuggestionBox(suggestion),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Original logic for multiple messages or non-initial single message
    List<Widget> messageWidgets = [];

    for (final message in messages) {
      // System messages
      if (message.isSystemMessage) {
        if (message.isInitialSystemMessage) {
          // Show initial welcome text + suggestion boxes
          List<String> suggestions = [];
          String welcomeText = "";
          final lines = message.text.split('\n');
          welcomeText = lines[0];
          for (int i = 2; i < lines.length; i++) {
            if (lines[i].startsWith('- ')) {
              suggestions.add(lines[i].substring(2));
            }
          }

          messageWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 16.0,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: CopyableBubble(
                          text: welcomeText,
                          child: FormattedText(
                            text: welcomeText,
                            textStyle: const TextStyle(
                              fontSize: 26,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children:
                          suggestions
                              .map(
                                (suggestion) => _buildSuggestionBox(suggestion),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          // Non-initial system message
          TextStyle systemStyle = TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          );
          messageWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4.0,
                horizontal: 16.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: CopyableBubble(
                    text: message.text,
                    child: FormattedText(
                      text: message.text,
                      textStyle: systemStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      } else {
        // Normal user/bot messages
        if (message.imageUrl != null) {
          // Bot image from URL
          messageWidgets.add(_buildImageUrlBubble(message));
        } else if (message.base64Image != null) {
          // Bot image from base64
          messageWidgets.add(_buildBase64ImageBubble(message));
        } else if (message.imagePath != null) {
          // Locally stored image (likely from the user)
          messageWidgets.add(_buildLocalImageBubble(message));
        } else if (message.asset != null) {
          // Image from AssetEntity (gallery)
          messageWidgets.add(_buildAssetImageBubble(message));
        }
        else {
          // Pure text
          messageWidgets.add(_buildTextBubble(message));
        }
      }
    }

    // Updated typing indicator: The animated breathing dot is aligned to the far left.
    if (isTyping) {
      messageWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: BreathingDot(), // Animated dot at the left side
            ),
          ),
        ),
      );
    }

    // If no messages and not typing, show a placeholder
    if (messages.isEmpty && !isTyping) {
      messageWidgets.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Text(
              "Chats will be displayed here...",
              style: TextStyle(fontSize: 18, color: Colors.grey[400]),
            ),
          ),
        ),
      );
    }

    // Use ListView only when there are multiple messages or non-initial ones
    return ListView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: messageWidgets,
    );
  }

  Widget _buildTextBubble(ChatMessage message) {
    // Align user text to the right, bot text to the left
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start, // Alignment
        children: [
          Flexible(
            child: CopyableBubble(
              text: message.text,
              child: Container(
                width:
                    message.isFullWidth
                        ? double
                            .infinity // Full width for AI messages
                        : null, // Default width
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color:
                      message.isUser
                          ? const Color.fromARGB(255, 30, 30, 30)
                          : Colors.black,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: FormattedText(
                  text: message.text,
                  textStyle: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalImageBubble(ChatMessage message) {
    // Show the user's captured image on the right, or bot image on left if needed
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start, // Alignment
        children: [
          ImageMessageWidgetIdentical( // Use the Identical Widget
            imagePath: message.imagePath!,
            isUser: message.isUser,
          ),
        ],
      ),
    );
  }

  Widget _buildAssetImageBubble(ChatMessage message) {
    // Show the user's selected image from gallery
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start, // Alignment
        children: [
          ImageMessageWidgetIdentical( // Use the Identical Widget
            asset: message.asset!,
            isUser: message.isUser,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUrlBubble(ChatMessage message) {
    // Usually bot-sent images (like from stable diffusion if you stored them remotely)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start, // Alignment
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    _globalContext(),
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ImageViewerScreen(imageUrl: message.imageUrl),
                    ),
                  );
                },
                child: Image.network(
                  message.imageUrl!,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBase64ImageBubble(ChatMessage message) {
    // Typically bot-sent images from HuggingFace (Stable Diffusion)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start, // Alignment
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    _globalContext(),
                    MaterialPageRoute(
                      builder:
                          (context) => ImageViewerScreen(
                            base64Image: message.base64Image,
                          ),
                    ),
                  );
                },
                child: Image.memory(
                  base64Decode(message.base64Image!),
                  errorBuilder:
                      (context, error, stackTrace) => const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionBox(String suggestion) {
    IconData iconData;
    if (suggestion.contains("Code questions")) {
      iconData = Icons.code;
    } else if (suggestion.contains("Math problems")) {
      iconData = Icons.calculate;
    } else if (suggestion.contains("Recipes")) {
      iconData = Icons.food_bank;
    } else if (suggestion.contains("chat about life")) {
      iconData = Icons.psychology;
    } else {
      iconData = Icons.lightbulb_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 18, 18, 18),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color.fromARGB(255, 61, 61, 61),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            suggestion,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Because we are in a stateless widget, we need a global context function for Navigator
  BuildContext _globalContext() {
    return scrollController.position.context.notificationContext ??
        scrollController.position.context.storageContext!;
  }
}

/// Widget for displaying a local image from file, preserving its aspect ratio.
/// **Identical Implementation for both ImagePath and Asset**
class ImageMessageWidgetIdentical extends StatelessWidget {
  final String? imagePath;
  final AssetEntity? asset;
  final bool isUser;

  const ImageMessageWidgetIdentical({
    Key? key,
    this.imagePath,
    this.asset,
    required this.isUser,
  }) :
    assert((imagePath != null && asset == null) || (imagePath == null && asset != null), "Either imagePath or Asset must be provided, but not both"),
    super(key: key);


  Future<Size> _getImageSize() async {
    if (imagePath != null) {
      final bytes = await File(imagePath!).readAsBytes();
      final image = await decodeImageFromList(bytes); // returns Future<ui.Image>
      return Size(image.width.toDouble(), image.height.toDouble());
    } else if (asset != null) {
      final bytes = await asset!.thumbnailDataWithSize(const ThumbnailSize(600, 600)); // Use thumbnail for size estimation
      if (bytes != null) {
        final image = await decodeImageFromList(bytes);
        return Size(image.width.toDouble(), image.height.toDouble());
      }
    }
    return Size.zero; // Default size if image fails to load
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _getImageSize(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != Size.zero) { // Check for non-zero size
          final size = snapshot.data!;
          final aspectRatio = size.width / size.height;

          return Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
            ),
            decoration: BoxDecoration(
              color:
                  isUser ? const Color.fromARGB(255, 30, 30, 30) : Colors.black,
              borderRadius: BorderRadius.circular(23.0),
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: GestureDetector(
                onTap: () async {
                  // Open the image in full screen
                  if (imagePath != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ImageViewerScreen(imagePath: imagePath),
                      ),
                    );
                  } else if (asset != null) {
                    final file = await asset!.file;
                    if (file != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ImageViewerScreen(imagePath: file.path),
                        ),
                      );
                    }
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: imagePath != null
                    ? Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => const Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                      )
                    : asset != null
                      ? FutureBuilder<Uint8List?>(
                          future: asset!.thumbnailDataWithSize(const ThumbnailSize(600, 600)),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return const Center(child: CircularProgressIndicator());
                            }
                          })
                      : const SizedBox(), // Should not reach here due to assert
                ),
              ),
            ),
          );
        } else {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isUser ? const Color.fromARGB(255, 30, 30, 30) : Colors.black,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}


/// Widget for displaying a AssetEntity image from gallery, preserving its aspect ratio.
//** Deprecated - Use ImageMessageWidgetIdentical instead **
class AssetMessageWidget extends StatelessWidget {
  final AssetEntity asset;
  final bool isUser;

  const AssetMessageWidget({
    Key? key,
    required this.asset,
    required this.isUser,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(600, 600)), // Adjust size as needed
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final imageData = snapshot.data!;
          return Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
            ),
            decoration: BoxDecoration(
              color:
                  isUser ? const Color.fromARGB(255, 30, 30, 30) : Colors.black,
              borderRadius: BorderRadius.circular(23.0),
            ),
            child: GestureDetector(
              onTap: () async {
                final file = await asset.file;
                if (file != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ImageViewerScreen(imagePath: file.path),
                    ),
                  );
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.memory(
                  imageData,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red),
                      ),
                ),
              ),
            ),
          );
        } else {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  isUser ? const Color.fromARGB(255, 30, 30, 30) : Colors.black,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}