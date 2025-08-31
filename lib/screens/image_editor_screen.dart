import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class ImageEditorScreen extends StatefulWidget {
  final String imagePath;

  const ImageEditorScreen({super.key, required this.imagePath});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  late File _imageFile;
  final bool _isProcessing = false;
  int _rotationDegrees = 0;
  bool _isGrayscale = false;
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _imageFile = File(widget.imagePath);
  }

  // We'll use Flutter's built-in transformation capabilities instead of image_cropper
  void _showCropDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crop Not Available'),
        content: const Text(
          'For this version, cropping is not available due to plugin compatibility issues. '
          'You can still rotate the image and apply filters.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _rotateImage(int degrees) {
    setState(() {
      _rotationDegrees = (_rotationDegrees + degrees) % 360;
    });
  }
  
  void _toggleGrayscale() {
    setState(() {
      _isGrayscale = !_isGrayscale;
    });
  }
  
  // We'll keep this functionality for a future update when we need more complex image processing
  
  Future<void> _saveAndExit() async {
    // For simple edits, we can just copy the file and apply the transformations when displayed
    // For more complex edits, we would need to use a rendering library
    final tempDir = await getTemporaryDirectory();
    final newPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await _imageFile.copy(newPath);
    if (mounted) Navigator.of(context).pop(savedFile.path);
  }

  void _applyFilter() {
    _toggleGrayscale();
  }

  @override
  Widget build(BuildContext context) {
    // Apply transformations to the image
    Widget imageWidget = Image.file(_imageFile);
    
    // Apply rotation if needed
    if (_rotationDegrees != 0) {
      imageWidget = Transform.rotate(
        angle: _rotationDegrees * 3.14159265359 / 180,
        child: imageWidget,
      );
    }
    
    // Apply grayscale if enabled
    if (_isGrayscale) {
      imageWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: imageWidget,
      );
    }

    // Wrap in RepaintBoundary for potential screen capture
    imageWidget = RepaintBoundary(
      key: _globalKey,
      child: imageWidget,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: _saveAndExit,
            tooltip: 'Done',
          ),
        ],
      ),
      body: Center(
        child: _isProcessing 
            ? const CircularProgressIndicator()
            : imageWidget,
      ),
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildEditorButton(Icons.crop, 'Crop', _showCropDialog),
              _buildEditorButton(Icons.rotate_left, 'Rotate Left', () => _rotateImage(-90)),
              _buildEditorButton(Icons.rotate_right, 'Rotate Right', () => _rotateImage(90)),
              _buildEditorButton(Icons.filter_b_and_w, 'B&W Filter', _applyFilter),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditorButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }
}
