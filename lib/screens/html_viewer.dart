// html_viewer.dart (Using webview_flutter)
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HtmlViewerScreen extends StatefulWidget {
  final String htmlContent;

  const HtmlViewerScreen({super.key, required this.htmlContent});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      if (widget.htmlContent.trim().isEmpty) {
        setState(() {
          _loadError = "Received empty HTML content.";
          _isLoading = false;
        });
        return;
      }

      // Create full HTML document
      final String htmlDocument = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            background-color: white;
            color: black;
            font-family: Arial, sans-serif;
            margin: 16px;
        }
    </style>
</head>
<body>
    ${widget.htmlContent}
</body>
</html>
''';

      final String contentBase64 = base64Encode(
        const Utf8Encoder().convert(htmlDocument),
      );
      final Uri dataUri = Uri.parse('data:text/html;base64,$contentBase64');

      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.white)
            ..setNavigationDelegate(
              NavigationDelegate(
                onPageStarted: (_) {
                  if (mounted) setState(() => _isLoading = true);
                },
                onPageFinished: (_) {
                  if (mounted) setState(() => _isLoading = false);
                },
                onWebResourceError: (error) {
                  // Fixed nullable check
                  if (mounted && (error.isForMainFrame ?? true)) {
                    setState(() {
                      _isLoading = false;
                      _loadError = "Error: ${error.description}";
                    });
                  }
                },
              ),
            );

      await _controller.loadRequest(dataUri);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = "Failed to load HTML: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "--- HtmlViewerScreen build (WebView - isLoading: $_isLoading, loadError: $_loadError) ---",
    );
    return Scaffold(
      // Flutter scaffold remains black
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Match app theme
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'HTML Preview (WebView)', // Clarify it uses WebView
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Stack(
        // Use Stack for layering WebView, loader, and error message
        children: [
          // --- Conditionally display WebView or Error Message ---
          if (_loadError == null)
            // WebView is the base layer if no error
            WebViewWidget(controller: _controller)
          else
            // Display error message if loading failed
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Failed to load HTML:\n$_loadError',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                ),
              ),
            ),

          // --- Loading Indicator ---
          // Show only when loading is in progress AND there isn't already an error displayed
          if (_isLoading && _loadError == null)
            const Center(
              child: CircularProgressIndicator(
                // Use a color that stands out on black/white
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.lightBlueAccent,
                ),
                strokeWidth: 4.0, // Make it slightly thicker
              ),
            ),
        ],
      ),
    );
  }
}
