import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class BreathingDot extends StatefulWidget {
  final Color color;
  final double size;
  final int cycles; // Number of breathing cycles
  final int durationMs; // Duration for one cycle in milliseconds
  final VoidCallback? onAnimationComplete; // Callback when animation completes

  const BreathingDot({
    Key? key,
    this.color = Colors.white,
    this.size = 25.0,
    this.cycles = 3,
    this.durationMs = 600,
    this.onAnimationComplete,
  }) : super(key: key);

  @override
  _BreathingDotState createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _cycleCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    _animation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cycleCount++;
        if (_cycleCount < widget.cycles) {
          _controller.reverse();
        } else {
          _controller.stop();
          if (widget.onAnimationComplete != null) {
            widget.onAnimationComplete!(); // Execute the callback
          }
        }
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _controller.forward(); // Start animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _animation,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class SelectImgWidget extends StatefulWidget {
  const SelectImgWidget({Key? key}) : super(key: key);

  @override
  _SelectImgWidgetState createState() => _SelectImgWidgetState();
}

class _SelectImgWidgetState extends State<SelectImgWidget>
    with SingleTickerProviderStateMixin {
  List<AssetEntity> images = [];
  AssetEntity? selectedImage;
  AssetEntity? _previewedImage;
  OverlayEntry? _previewOverlayEntry;
  late AnimationController _animationController;
  bool _loadingImages = true; // Track initial image loading state

  @override
  void initState() {
    super.initState();
    _requestPermissionAndFetchImages();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removePreviewOverlay();
    super.dispose();
  }

  Future<void> _requestPermissionAndFetchImages() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      await _fetchImages();
    } else {
      PhotoManager.openSetting();
    }
  }

  Future<void> _fetchImages() async {
    try {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: FilterOption(
            sizeConstraint: SizeConstraint(minWidth: 100, minHeight: 100),
          ),
          orders: [OrderOption(type: OrderOptionType.createDate, asc: false)],
        ),
      );

      List<AssetEntity> allImages = [];
      Set<String> uniqueImageIds = <String>{};

      if (albums.isNotEmpty) {
        for (var album in albums) {
          try {
            List<AssetEntity> media = await album.getAssetListPaged(
              page: 0,
              size: 1000,
            );
            for (var image in media) {
              if (!uniqueImageIds.contains(image.id)) {
                allImages.add(image);
                uniqueImageIds.add(image.id);
              }
            }
          } catch (e) {
            print("Error fetching images from album ${album.name}: $e");
          }
        }

        allImages.sort((a, b) {
          return b.createDateTime.compareTo(a.createDateTime);
        });

        setState(() {
          images = allImages;
        });
      }
    } catch (e) {
      print("Error fetching albums: $e");
    } finally {
      // Set _loadingImages to false after image fetching is done (success or failure)
      // The animation completion callback will now handle setting it to false
    }
  }

  void _onImageTap(AssetEntity image) {
    if (selectedImage == null) {
      setState(() {
        selectedImage = image;
        _animationController.forward(from: 0.0);
      });
    } else if (selectedImage!.id == image.id) {
      setState(() {
        selectedImage = null;
        _animationController.reverse();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("The model only supports one image at a time"),
        ),
      );
    }
  }

  void _showPreviewOverlay(AssetEntity image) {
    _previewedImage = image;
    _previewOverlayEntry = _createPreviewOverlayEntry();
    Overlay.of(context).insert(_previewOverlayEntry!);
  }

  void _removePreviewOverlay() {
    if (_previewOverlayEntry != null) {
      _previewOverlayEntry!.remove();
      _previewOverlayEntry = null;
      _previewedImage = null;
    }
  }

  OverlayEntry _createPreviewOverlayEntry() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final overlaySizeFactor = 0.8;
    final overlayWidth = screenWidth * overlaySizeFactor;
    final overlayHeight = screenHeight * overlaySizeFactor;
    final marginHorizontal = (screenWidth - overlayWidth) / 2;
    final marginVertical = (screenHeight - overlayHeight) / 2;
    final barrierRadius = BorderRadius.circular(20);

    return OverlayEntry(
      builder:
          (context) => Positioned(
            left: 0,
            top: 0,
            width: screenWidth,
            height: screenHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _removePreviewOverlay,
              onLongPressEnd: (details) {
                _removePreviewOverlay();
              },
              onLongPressCancel: () {
                _removePreviewOverlay();
              },
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      color: Colors.black54,
                      width: screenWidth,
                      height: screenHeight,
                      child: ClipRRect(
                        borderRadius: barrierRadius,
                        child: Container(color: Colors.black54),
                      ),
                    ),
                    Positioned(
                      left: marginHorizontal,
                      top: marginVertical,
                      width: overlayWidth,
                      height: overlayHeight,
                      child:
                          _previewedImage != null
                              ? FutureBuilder<Uint8List?>(
                                future: _previewedImage!.originBytes,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: InteractiveViewer(
                                        panEnabled: true,
                                        minScale: 0.5,
                                        maxScale: 4.0,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Image.memory(
                                            snapshot.data!,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return BreathingDot(
                                      color: Colors.white,
                                      durationMs: 600,
                                      cycles: 3,
                                    ); // BreathingDot for preview loading
                                  } else {
                                    return const Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.white),
                                    );
                                  }
                                },
                              )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Image Gallery"),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  _loadingImages
                      ? Center(
                        child: BreathingDot(
                          durationMs: 800,
                          cycles: 2,
                          onAnimationComplete: () {
                            setState(() {
                              _loadingImages =
                                  false; // Set loading to false after animation
                            });
                          },
                        ),
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: images.length,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          final isSelected =
                              selectedImage != null &&
                              selectedImage!.id == image.id;

                          return GestureDetector(
                            onTap: () => _onImageTap(image),
                            onLongPressStart: (details) {
                              _showPreviewOverlay(image);
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<Uint8List?>(
                                    future: image.thumbnailDataWithSize(
                                      const ThumbnailSize(400, 400),
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                              ConnectionState.done &&
                                          snapshot.hasData) {
                                        return Image.memory(
                                          snapshot.data!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return const SizedBox.shrink(); // Fallback widget
                                    },
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: isSelected ? 0.3 : 0.0,
                                  child: Container(color: Colors.white),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: ScaleTransition(
                                      scale: CurvedAnimation(
                                        parent: _animationController,
                                        curve: Curves.easeInOutBack,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1),
                    ),
                    child: const Text("Close"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedImage != null) {
                        Navigator.pop(context, selectedImage);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please select an image to upload"),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.white, width: 1),
                    ),
                    child: const Text(
                      "Upload",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
